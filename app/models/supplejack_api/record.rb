# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/record.rb
  class Record < ActiveResource::Base
    self.site = "#{ENV['API_HOST']}/harvester"
    self.collection_parser = EnrichmentRecordCollection
    include Enrichable

    def self.find(query, page)
      Rails.logger.info "query: #{query}"
      Rails.logger.info "page: #{page}"
      super(:all, params: { search: query, search_options: page, api_key: ENV['HARVESTER_API_KEY'] })
    rescue ActiveResource::ServerError => e
      Airbrake.notify(e, error_message: "The api request failed with: query: #{query} and page: #{page}.  #{e&.message}")
      raise
    end
  end
end
