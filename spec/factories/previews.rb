# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :preview do
    parser_code { 'def foo;end' }
    parser_id   { 123 }
    index       { 0 }
    user_id     { 123 }
    format      { 'json' }
  end
end
