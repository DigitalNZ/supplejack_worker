# frozen_string_literal: true

# app/models/state.rb
class State
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :abstract_job

  field :page,        type: Integer
  field :per_page,    type: Integer
  field :limit,       type: Integer
  field :counter,     type: Integer
  field :base_urls,   type: Array
  field :total_selector, type: String
end
