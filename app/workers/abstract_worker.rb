class AbstractWorker
  include Sidekiq::Worker

  def stop_harvest?(job)
    job.reload

    if stop = job.stopped? || job.errors_over_limit?
      job.finish!
    end

    stop
  end
end