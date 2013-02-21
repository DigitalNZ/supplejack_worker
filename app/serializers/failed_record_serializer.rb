class FailedRecordSerializer < ActiveModel::Serializer

  attributes :exception_class, :message, :backtrace
end