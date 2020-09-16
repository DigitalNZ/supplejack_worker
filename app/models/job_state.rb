# frozen_string_literal: true

# app/models/job_state.rb
class JobState
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url,        type: String
end
