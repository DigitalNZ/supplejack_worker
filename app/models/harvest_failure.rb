# frozen_string_literal: true
class HarvestFailure
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :exception_class, type: String
  field :message,         type: String
  field :backtrace,       type: Array

  embedded_in :harvest_job
end
