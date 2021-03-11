# frozen_string_literal: true

FactoryBot.define do
  factory :state do
    page      { 1 }
    per_page  { 10 }
    limit     { 100 }
    counter   { 1 }
    base_urls { [] }
    created_at { Time.now }
  end
end
