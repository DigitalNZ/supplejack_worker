class AbstractWorker
  include Sidekiq::Worker

  attr_reader :job_id

  def stop_harvest?
    job.reload

    if stop = job.stopped? || job.errors_over_limit?
      job.finish!
    end

    stop
  end

  def job
    @job ||= AbstractJob.find(self.job_id)
  end

  protected

  def api_update_finished?
    job.reload
    job.posted_records_count == job.records_count
  end
end