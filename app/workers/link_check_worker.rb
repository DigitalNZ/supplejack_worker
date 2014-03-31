class LinkCheckWorker
  include Sidekiq::Worker
  include ValidatesResource

  sidekiq_options :retry => 100

  sidekiq_retry_in { |count| 2 * Random.rand(1..5) }

  def perform(link_check_job_id, strike=0)
    @link_check_job_id = link_check_job_id
    begin
      if link_check_job.present? && link_check_job.source.present?
        unless rules.present?
          Rails.logger.error "MissingLinkCheckRuleError: No LinkCheckRule found for source_id: [#{link_check_job.source_id}]"
          Airbrake.notify(MissingLinkCheckRuleError.new(link_check_job.source_id))
          return
        end

        if rules.active
          response = link_check(link_check_job.url, link_check_job.source._id)
          if validate_link_check_rule(response, link_check_job.source._id)
            set_record_status(link_check_job.record_id, "active") if strike > 0
          else
            suppress_record(link_check_job_id, link_check_job.record_id, strike)
          end
        end
      end
    rescue RestClient::ResourceNotFound => e
      suppress_record(link_check_job_id, link_check_job.record_id, strike)
    rescue StandardError => e
      Airbrake.notify(e, error_message: "There was a unexpected error when trying to POST to #{ENV['API_HOST']}/harvester/records/#{link_check_job.record_id} to update status to supressed")
    end
  end

  private

  def add_record_stats(record_id, status)
    status = "activated" if status == "active"
    collection_stats.add_record!(record_id, status, link_check_job.url)
  end

  def collection_stats
    @collection_stats ||= CollectionStatistics.find_or_create_by({day: Date.today, source_id: link_check_job.source_id})
  end

  def link_check_job
    @link_check_job ||= LinkCheckJob.find(@link_check_job_id) rescue nil
  end

  def rules
    link_check_rule(link_check_job.source._id)
  end

  def link_check(url, collection)
    Sidekiq.redis do |conn| 
      if conn.setnx(collection, 0)
        conn.expire(collection, rules.try(:throttle) || 2)
        RestClient.get(url)
      else
        raise ThrottleLimitError.new("Hit #{collection} throttle limit, LinkCheckJob will automatically retry")
      end
    end
  end

  def suppress_record(link_check_job_id, record_id, strike)
    timings = {0 => 1.hours, 1 => 5.hours, 2 => 72.hours}
    
    if strike >= 3
      set_record_status(record_id, "deleted")
    else
      set_record_status(record_id, "suppressed") unless strike > 0
      LinkCheckWorker.perform_in(timings[strike], link_check_job_id, strike + 1)
    end
  end

  def set_record_status(record_id, status)
    begin
      RestClient.put("#{ENV['API_HOST']}/harvester/records/#{record_id}", {record: {status: status}})
      add_record_stats(record_id, status)
    rescue StandardError => e
      Rails.logger.warn("Record not found when updating status in LinkChecking. Ignoring.")
    end
  end
end