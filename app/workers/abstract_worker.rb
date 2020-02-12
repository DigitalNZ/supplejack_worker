# frozen_string_literal: true

# app/workers/abstract_worker.rb
class AbstractWorker
  include Sidekiq::Worker

  attr_reader :job_id

  def stop_harvest?
    job.reload
    
    return true if job.finished?

    job.finish! if job.errors_over_limit?

    return (job.stopped? || job.errors_over_limit?)
  end

  def job
    @job ||= AbstractJob.find(job_id.to_s)
  end

  protected

  def sanitize_id(id)
    id.is_a?(Hash) ? id['$oid'] : id
  end

  def api_update_finished?
    job.reload
    job.posted_records_count == job.records_count
  end

  def process_response(response)
    # raising an Exception will cause Sidekiq to retry the job.
    unless response['status'] == 'success'
      # This scenario is because we cannot send an Array to the manager
      # via Active Resource
      job.retried_records << response['record_id']
      job.save!
      job.set(retried_records_count: job.retried_records.uniq.count)
      parser_id = job.parser.id

      raise Supplejack::HarvestError.new(response['message'],
                                         response['backtrace'],
                                         response['raw_data'],
                                         parser_id)
    end

    job.set(updated_at: Time.zone.now.change(usec: 0), last_posted_record_id: response['record_id'])
    job.inc(posted_records_count: 1)
  end
end
