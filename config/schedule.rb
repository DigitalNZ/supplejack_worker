# frozen_string_literal: true
env :PATH, ENV['PATH'] if @enviroment == 'development'

every :day, at: '2:00am' do
  runner 'HarvestJob.clear_raw_data'
end

every 4.minutes do
  runner 'ExpensiveCrons.call'
end

# Mails the stats for collection to Harvest operator
every 1.day, at: '6:00 am' do
  runner 'CollectionStatistics.email_daily_stats'
end

# Checks source LinkCheckRules and suppress/unsuppress conllection.
every 2.hours do
  runner 'EnqueueSourceChecksWorker.perform_async'
end

# Clears old Sidekiq Jobs from Mongo
every :monday, at: '2:30am' do
  rake 'sidekiq_jobs:purge'
end
