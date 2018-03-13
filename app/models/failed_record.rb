# frozen_string_literal: true

# app/models/failed_record.rb
class FailedRecord
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :exception_class, type: String
  field :message,         type: String
  field :backtrace,       type: Array
  field :raw_data,        type: String

  embedded_in :harvest_job
end
