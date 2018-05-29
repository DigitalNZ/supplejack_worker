# frozen_string_literal: true

# app/serializer/failed_record_serializer.rb
class FailedRecordSerializer < ActiveModel::Serializer
  attributes :exception_class, :message, :backtrace, :raw_data, :created_at
end
