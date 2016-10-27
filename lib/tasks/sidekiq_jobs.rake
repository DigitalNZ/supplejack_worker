namespace :sidekiq_jobs do
  desc 'Delets all old jobs from Mongo'
  task purge: :environment do
    AbstractJob.where(:created_at.lte => (Date.today - 30)).delete_all
    HarvestJob.where(:created_at.lte => (Date.today - 30)).delete_all
    LinkCheckJob.where(:created_at.lte => (Date.today - 30)).delete_all
  end
end
