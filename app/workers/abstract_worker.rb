# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class AbstractWorker
  include Sidekiq::Worker

  attr_reader :job_id

  def stop_harvest?
    job.reload

    # When a harvest operator manually stops a job,
    # it gets finished below, but we cannot (currently) stop the 
    # Sidekiq job so this will be executed again with status 'finished'
    # the next time stop_harvest? is called in the loop
    return true if job.finished?

    if stop = job.stopped? || job.errors_over_limit?
      job.finish!
    end

    stop
  end

  def job
    @job ||= AbstractJob.find(self.job_id.to_s)
  end

  protected

  def sanitize_id(id)
    id.is_a?(Hash) ? id["$oid"] : id
  end

  def api_update_finished?
    job.reload
    job.posted_records_count == job.records_count
  end

  def process_response(response)
    job.set(last_posted_record_id: response['record_id'])
    job.inc(posted_records_count: 1)

    return if response['status'] == 'success'

    job.failed_records << FailedRecord.new(
      exception_class: response['exception_class'],
      message: response['message'],
      raw_data: response['raw_data']
    )
  end
end
