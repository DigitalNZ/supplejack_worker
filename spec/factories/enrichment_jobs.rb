# frozen_string_literal: true
FactoryBot.define do
  factory :enrichment_job do
    start_time           { Time.now }
    environment          { 'test' }
    enrichment           { 'ndha_rights' }
    records_count        { 100 }
    posted_records_count { 100 }

    sequence(:parser_id)  { |n| "abc#{n}" }
    sequence(:version_id) { |n| "abc#{n}" }
    sequence(:user_id)    { |n| "abc#{n}" }

    association :harvest_schedule, factory: :harvest_schedule
    association :harvest_job, factory: :harvest_job
  end
end
