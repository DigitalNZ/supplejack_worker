# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

env :PATH, ENV['PATH'] if @enviroment == 'development'

every :day, at: '2:00am' do
  runner 'HarvestJob.clear_raw_data'
end

every 3.minutes do
  runner 'HarvestSchedule.create_one_off_jobs'
end

every 5.minutes do
  runner 'NetworkChecker.check'
end

every 7.minutes do
  runner 'HarvestSchedule.create_recurrent_jobs'
end

every 1.day, at: '6:00 am' do
  runner 'CollectionStatistics.email_daily_stats'
end

every 2.hours do
  runner 'EnqueueSourceChecksWorker.perform_async'
end
