every :day, at: "2:00am" do
  runner "HarvestJob.clear_raw_data"
end

every 5.minutes do
  runner "HarvestSchedule.create_one_off_jobs"
  runner "HarvestSchedule.create_recurrent_jobs"
end

every 1.day, :at => '6:00 am' do
  runner "CollectionStatistics.email_daily_stats"
end

every 5.minutes do
  runner "NetworkChecker.check"
end

every 2.hours do
  runner "EnqueueCollectionChecksWorker.perform_async"
end
