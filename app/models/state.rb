# frozen_string_literal: true

# app/models/state.rb
class State
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :harvest_job

  field :page,        type: Integer
  field :per_page,    type: Integer
  field :limit,       type: Integer
  field :counter,     type: Integer
end
