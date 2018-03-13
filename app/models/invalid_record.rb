# frozen_string_literal: true

# app/models/invalid_record.rb
class InvalidRecord
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :raw_data,        type: String
  field :error_messages,  type: Array

  embedded_in :harvest_job
end
