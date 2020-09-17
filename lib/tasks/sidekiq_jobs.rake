# frozen_string_literal: true
namespace :sidekiq_jobs do
  desc 'Delets old jobs from Mongo'
  task purge: :environment do
    # Keeping jobs for last 500 days. These are Harvest Jobs
    AbstractJob.where(:updated_at.lte => (Date.today - 500)).delete_all

    LinkCheckJob.where(:created_at.lte => (Date.today - 7)).delete_all

    AbstractJob.where(:created_at.lte => (Date.today - 7),
                      environment: 'preview').delete_all
  end

  task :recover_interrupted_jobs do
    p 'Recovering interrupted jobs ...'

    harvest_jobs = HarvestJob.where(status: 'ready')

    if harvest_jobs.any?
      p "There are #{harvest_jobs.count} HarvestJobs ready to start ..."

      harvest_jobs.each do |harvest_job|
        p "Starting HarvestJob with id #{harvest_job.id}"
        harvest_job.enqueue
      end
    else
      p 'There are no HarvestJobs ready to start.'
    end
  end
end
