# frozen_string_literal: true

# app/serializers/invalid_record_serializer.rb
class InvalidRecordSerializer < ActiveModel::Serializer
  attributes :raw_data, :error_messages, :created_at
end
