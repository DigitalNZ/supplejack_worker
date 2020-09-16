# frozen_string_literal: true

# app/workers/recover_active_jobs_worker.rb
class RecoverActiveJobsWorker
  include Sidekiq::Worker

  def perform
    p 'Recovering active jobs...'
  end
end
