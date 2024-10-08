# frozen_string_literal: true

# This class is ONLY used by SupplejackCommon,
# however we have 2 different implementations
# one for Manager and one for Worker

# app/models/snippet.rb
class Snippet < ActiveResource::Base
  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  def self.find_by_name(name, environment)
    find(:one, from: :current_version, params: { name:,
                                                 environment: })
  rescue StandardError => e
    Rails.logger.error "Snippet with name: #{name} was not found"
    ElasticAPM.report(e)
    nil
  end
end
