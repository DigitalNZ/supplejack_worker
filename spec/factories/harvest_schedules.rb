# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :harvest_schedule do
    start_time '2013-02-26 16:09:29'
    cron '* * * * *'

    environment   'test'
    sequence(:parser_id) { |n| "abc#{n}" }
  end
end
