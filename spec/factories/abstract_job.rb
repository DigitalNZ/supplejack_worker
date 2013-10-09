FactoryGirl.define do
  factory :abstract_job do
    start_time    Time.now
    environment   "test"

    sequence(:parser_id)  {|n| "abc#{n}" }
    sequence(:version_id) {|n| "abc#{n}" }
    sequence(:user_id)    {|n| "abc#{n}" }
  end
end