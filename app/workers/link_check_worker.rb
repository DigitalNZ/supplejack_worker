# frozen_string_literal: true

# app/workers/link_check_worker.rb
class LinkCheckWorker
  include Sidekiq::Worker
  include ValidatesResource

  sidekiq_options retry: 100, queue: 'low'

  sidekiq_retry_in { |_count| 2 * Random.rand(1..5) }

  def perform(job_id, strike = 0)
    @job_id = job_id
    return unless job.present? && job.source.present?

    Sidekiq.logger.info "LinkCheckWorker[#{job.record_id}]: Starting check for url #{job.url} in job #{job_id} with strike #{strike}"

    begin
      if rules.blank?
        Sidekiq.logger.error "LinkCheckWorker[#{job.record_id}]: MissingLinkCheckRuleError: No LinkCheckRule found for source_id: [#{job.source_id}]"
        ElasticAPM.report(MissingLinkCheckRuleError.new(job.source_id))
        return
      end

      if rules.active
        response = link_check(job.url, job.source.id)
        if response && validate_link_check_rule(response, job.source.id)
          if strike.positive?
            Sidekiq.logger.info "LinkCheckWorker[#{job.record_id}]: Unsuppressing Record for landing_url #{job.url}"
            set_record_status(job.record_id, 'active')
          end
        else
          suppress_record(job_id, job.record_id, strike)
        end
      end
    rescue ThrottleLimitError
      # No operation here. Prevents ElasticAPM from notifying ThrottleLimitError.
    rescue StandardError => e
      Sidekiq.logger.info "LinkCheckWorker[#{job.record_id}]: There was an unexpected error."
      ElasticAPM.report(e)
      ElasticAPM.report_message("There was a unexpected error when trying to POST to #{ENV['API_HOST']}/harvester/records/#{job.record_id} to update status to supressed")
    end
  end

  private
    def add_record_stats(record_id, status)
      status = 'activated' if status == 'active'

      Sidekiq.logger.info "LinkCheckWorker[#{record_id}]: CollectionStatistics updated with status = #{status}"
      collection_stats.add_record!(record_id, status, job.url)
    end

    def collection_stats
      @collection_stats ||= CollectionStatistics.find_or_create_by(day: Time.zone.today, source_id: job.source_id)
    end

    def job
      @job ||= begin
                 LinkCheckJob.find(@job_id)
               rescue StandardError
                 nil
               end
    end

    def rules
      link_check_rule(job.source.id)
    end

    def link_check(url, collection)
      Sidekiq.redis do |conn|
        if conn.setnx(collection, 0)
          conn.expire(collection, rules.try(:throttle) || 2)
          begin
            RestClient.get(url)
          rescue StandardError => e
            Sidekiq.logger.info "ResctClient get failed for #{url}. Error: #{e.message}"
            return nil
          end
        else
          Sidekiq.logger.info("Hit #{collection} throttle limit, LinkCheckJob will automatically retry job #{@job_id}")
          raise ThrottleLimitError, "Hit #{collection} throttle limit, LinkCheckJob will automatically retry job #{@job_id}"
        end
      end
    end

    def suppress_record(job_id, record_id, strike)
      timings = [1.hour, 23.hours]

      if strike >= 2
        Sidekiq.logger.info "LinkCheckWorker[#{record_id}]: Deleting Record"
        set_record_status(record_id, 'deleted')
      else
        if strike.zero?
          Sidekiq.logger.info "LinkCheckWorker[#{record_id}]: Suppressing Record"
          set_record_status(record_id, 'suppressed')
        end

        Sidekiq.logger.info "LinkCheckWorker[#{record_id}]: Scheduling re-check in #{timings[strike] / 3600} hours"
        LinkCheckWorker.perform_in(timings[strike], job_id, strike + 1)
      end
    end

    def set_record_status(record_id, status)
      Api::Record.put(record_id, { record: { status: status } })
      add_record_stats(record_id, status)
    rescue StandardError
      Sidekiq.logger.warn("LinkCheckWorker[#{record_id}]: Record not found when updating status = #{status} in LinkChecking. Ignoring.")
    end
end
