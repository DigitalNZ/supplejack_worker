# frozen_string_literal: true

# app/models/harvest_failure.rb
class EnrichmentFailure
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :exception_class, type: String
  field :message,         type: String
  field :backtrace,       type: Array

  embedded_in :enrichment_job
end
