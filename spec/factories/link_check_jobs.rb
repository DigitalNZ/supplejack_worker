# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :link_check_job do
    url 'http://google.co.nz'
    record_id 123
    source_id 'source_id'
  end
end
