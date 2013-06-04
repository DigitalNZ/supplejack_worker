class InvalidRecordSerializer < ActiveModel::Serializer

  attributes :raw_data, :error_messages, :created_at
end