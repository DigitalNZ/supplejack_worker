# frozen_string_literal: true

# app/workers/link_check_worker.rb
class LinkCheckWorker
  include Sidekiq::Worker
  include ValidatesResource

  sidekiq_options retry: 100, queue: 'low'

  sidekiq_retry_in { |_count| 2 * Random.rand(1..5) }

  def perform(link_check_job_id, strike = 0)
    Sidekiq.logger.info "Starting LinkCheckWorker for #{link_check_job_id} with strike #{strike}"
    @link_check_job_id = link_check_job_id
    begin
      if link_check_job.present? && link_check_job.source.present?
        if rules.blank?
          Sidekiq.logger.error "MissingLinkCheckRuleError: No LinkCheckRule found for source_id: [#{link_check_job.source_id}]"
          Airbrake.notify(MissingLinkCheckRuleError.new(link_check_job.source_id))
          return
        end

        if rules.active
          response = link_check(link_check_job.url, link_check_job.source.id)
          if response && validate_link_check_rule(response, link_check_job.source.id)
            Sidekiq.logger.info "Unsuppressing Record for landing_url #{link_check_job.url}"
            set_record_status(link_check_job.record_id, 'active') if strike.positive?
          else
            Sidekiq.logger.info "Suppressing Record for landing_url #{link_check_job.url}"
            suppress_record(link_check_job_id, link_check_job.record_id, strike)
          end
        end
      end
    rescue ThrottleLimitError
      # No operation here. Prevents Airbrake from notifying ThrottleLimitError.
    rescue StandardError => e
      Airbrake.notify(e, error_message: "There was a unexpected error when trying to POST to #{ENV['API_HOST']}/harvester/records/#{link_check_job.record_id} to update status to supressed")
    end
  end

  private

  def add_record_stats(record_id, status)
    status = 'activated' if status == 'active'
    collection_stats.add_record!(record_id, status, link_check_job.url)
  end

  def collection_stats
    @collection_stats ||= CollectionStatistics.find_or_create_by(day: Time.zone.today, source_id: link_check_job.source_id)
  end

  def link_check_job
    @link_check_job ||= begin
                          LinkCheckJob.find(@link_check_job_id)
                        rescue StandardError
                          nil
                        end
  end

  def rules
    link_check_rule(link_check_job.source.id)
  end

  def link_check(url, collection)
    Sidekiq.redis do |conn|
      if conn.setnx(collection, 0)
        conn.expire(collection, rules.try(:throttle) || 2)
        begin
          RestClient.get(url)
        rescue StandardError => e
          Sidekiq.logger.info "ResctClient get failed for #{url}. Error: #{e.message}"
          # This return will make the record to be suppressed
          return nil
        end
      else
        Sidekiq.logger.info("Hit #{collection} throttle limit, LinkCheckJob will automatically retry job #{@link_check_job_id}")
        raise ThrottleLimitError, "Hit #{collection} throttle limit, LinkCheckJob will automatically retry job #{@link_check_job_id}"
      end
    end
  end

  def suppress_record(link_check_job_id, record_id, strike)
    timings = [1.hour, 5.hours, 72.hours]

    if strike >= 3
      set_record_status(record_id, 'deleted')
    else
      set_record_status(record_id, 'suppressed') unless strike.positive?
      LinkCheckWorker.perform_in(timings[strike], link_check_job_id, strike + 1)
    end
  end

  def set_record_status(record_id, status)
    RestClient.put("#{ENV['API_HOST']}/harvester/records/#{record_id}", record: { status: status }, api_key: ENV['HARVESTER_API_KEY'])
    add_record_stats(record_id, status)
  rescue StandardError
    Sidekiq.logger.warn('Record not found when updating status in LinkChecking. Ignoring.')
  end
end
