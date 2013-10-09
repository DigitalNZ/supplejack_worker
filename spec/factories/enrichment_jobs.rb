FactoryGirl.define do
  factory :enrichment_job do
    start_time    Time.now
    environment   "test"
    enrichment    "ndha_rights"
    records_count 100
    posted_records_count 100

    sequence(:parser_id)  {|n| "abc#{n}" }
    sequence(:version_id) {|n| "abc#{n}" }
    sequence(:user_id)    {|n| "abc#{n}" }
  end
end