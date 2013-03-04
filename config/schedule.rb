# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

every :day, at: "2:00am" do
  runner "HarvestJob.clear_raw_data"
end

every 15.minutes do
  runner "HarvestSchedule.create_one_off_jobs"
  runner "HarvestSchedule.create_recurrent_jobs"
end
