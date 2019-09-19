# frozen_string_literal: true
FactoryBot.define do
  factory :abstract_job do
    start_time       Time.now
    environment      'test'

    sequence(:parser_id)  { |n| "abc#{n}" }
    sequence(:version_id) { |n| "abc#{n}" }
    sequence(:user_id)    { |n| "abc#{n}" }

    association :harvest_schedule, factory: :harvest_schedule
  end
end
