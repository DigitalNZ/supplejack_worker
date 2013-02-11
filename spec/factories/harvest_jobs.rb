FactoryGirl.define do
  factory :harvest_job do
    limit         nil
    start_time    Time.now
  end
end