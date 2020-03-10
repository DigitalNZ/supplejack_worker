# frozen_string_literal: true

# app/workers/source_check_worker.rb
class SourceCheckWorker
  include Sidekiq::Worker
  include ValidatesResource
  sidekiq_options queue: 'default'

  attr_reader :source

  def perform(id)
    @source = Source.find(id)

    source_up = source_records.any? { |r| up?(r) }

    suppress_collection if !source_up && source_active?
    activate_collection if source_up && !source_active?
  end

  private
    def source_records
      JSON.parse(
        RestClient.get(
          "#{ENV['API_HOST']}/harvester/sources/#{source.id}/link_check_records",
          params: { api_key: ENV['HARVESTER_API_KEY'] }
        )
      )
    end

    def source_active?
      collection = JSON.parse(
        RestClient.get(
          "#{ENV['API_HOST']}/harvester/sources/#{source.id}",
          params: { api_key: ENV['HARVESTER_API_KEY'] }
        )
      )
      collection['status'] == 'active'
    end

    def get(landing_url)
      RestClient.get(landing_url)
    rescue StandardError
      nil
    end

    def up?(landing_url)
      return true if landing_url.nil?
      return unless (response = get(landing_url))

      validate_link_check_rule(response, source.id)
    end

    def suppress_collection
      RestClient.put(
        "#{ENV['API_HOST']}/harvester/sources/#{source.id}",
        source: { status: 'suppressed', status_updated_by: 'LINK CHECKER' },
        api_key: ENV['HARVESTER_API_KEY']
      )
      CollectionMailer.collection_status(source, 'suppressed').deliver
    end

    def activate_collection
      RestClient.put(
        "#{ENV['API_HOST']}/harvester/sources/#{source.id}",
        source: { status: 'active', status_updated_by: 'LINK CHECKER' },
        api_key: ENV['HARVESTER_API_KEY']
      )
      CollectionMailer.collection_status(source, 'activated').deliver
    end
end
