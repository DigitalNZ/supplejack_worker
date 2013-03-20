FactoryGirl.define do
  factory :enrichment_job do
    start_time    Time.now
    status        "active"
    environment   "test"
    enrichment    "ndha_rights"

    sequence(:parser_id)  {|n| "abc#{n}" }
    sequence(:version_id) {|n| "abc#{n}" }
    sequence(:user_id)    {|n| "abc#{n}" }
  end
end