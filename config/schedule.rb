every :day, at: "2:00am" do
  runner "HarvestJob.clear_raw_data"
end

every 5.minutes do
  runner "HarvestSchedule.create_one_off_jobs"
  runner "HarvestSchedule.create_recurrent_jobs"
end
