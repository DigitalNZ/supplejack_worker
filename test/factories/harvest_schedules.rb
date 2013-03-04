# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :harvest_schedule do
    harvest_job_id "MyString"
    start_time "2013-02-26 16:09:29"
    cron "MyString"
  end
end
