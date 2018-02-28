# frozen_string_literal: true
class FailedRecordSerializer < ActiveModel::Serializer
  attributes :exception_class, :message, :backtrace, :raw_data, :created_at
end
