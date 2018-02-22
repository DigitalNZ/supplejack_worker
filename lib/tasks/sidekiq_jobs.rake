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
end
