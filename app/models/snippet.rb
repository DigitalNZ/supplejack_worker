# frozen_string_literal: true
# This class is ONLY used by SupplejackCommon,
# however we have 2 different implementations
# one for Manager and one for Worker
class Snippet < ActiveResource::Base
  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  def self.find_by_name(name, environment)
    snippet = find(:one, from: :current_version, params: { name: name, environment: environment })
  rescue StandardError => e
    # TODO: Rescue a specific exception
    Rails.logger.error "Snippet with name: #{name} was not found"
    Airbrake.notify(e)
    return nil
  end
end
