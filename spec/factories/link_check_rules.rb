# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :link_check_rule do
    sequence(:source_id) { |n| "abc#{n}" }
    xpath                { '/xpath' }
    status_codes         { '404' }
  end
end
