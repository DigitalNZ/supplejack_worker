# frozen_string_literal: true

module SupplejackApi
  class Record < ActiveResource::Base
    self.site = "#{ENV['API_HOST']}/harvester"
    self.collection_parser = EnrichmentRecordCollection
    include Enrichable

    def self.find(query, page)
      super(:all, params: { search: query, search_options: { page: page }, api_key: ENV['HARVESTER_API_KEY']})
    end
  end
end
