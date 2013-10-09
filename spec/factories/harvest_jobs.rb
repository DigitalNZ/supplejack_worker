FactoryGirl.define do
  factory :harvest_job do
    limit         nil
    start_time    Time.now
    environment   "test"

    sequence(:parser_id)  {|n| "abc#{n}" }
    sequence(:version_id) {|n| "abc#{n}" }
    sequence(:user_id)    {|n| "abc#{n}" }
  end
end