class InvalidRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::SerializerSupport

  field :raw_data,        type: String
  field :error_messages,  type: Array

  embedded_in :harvest_job

end