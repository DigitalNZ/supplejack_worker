class FailedRecordSerializer < ActiveModel::Serializer

  attributes :exception_class, :message, :backtrace, :raw_data
end