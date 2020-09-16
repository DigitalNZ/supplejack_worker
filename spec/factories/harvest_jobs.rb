# frozen_string_literal: true
FactoryBot.define do
  factory :harvest_job do
    limit         nil
    start_time    Time.now
    environment   'test'

    sequence(:parser_id)  { |n| "abc#{n}" }
    sequence(:version_id) { |n| "abc#{n}" }
    sequence(:user_id)    { |n| "abc#{n}" }

    association :harvest_schedule, factory: :harvest_schedule

    trait :states do
      after(:create) do |harvest_job|
        harvest_job.job_states << create_list(:job_state, 3)
      end
    end
  end
end
