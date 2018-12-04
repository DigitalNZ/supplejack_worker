# frozen_string_literal: true

# app/models/source.rb
class Source < ActiveResource::Base
  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  schema do
    attribute :partner_id,          :string
    attribute :source_id,           :string
    attribute :collection_rules_id, :string
  end
end
