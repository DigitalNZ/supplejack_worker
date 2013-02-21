class InvalidRecordSerializer < ActiveModel::Serializer

  attributes :raw_data, :error_messages
end