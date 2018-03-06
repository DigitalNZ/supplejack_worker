# frozen_string_literal: true
module SupplejackApi
  class PreviewRecord < ActiveResource::Base
    self.site = "#{ENV['API_HOST']}/harvester"
    include Enrichable

    def self.find(query, *_page)
      super(:all, params: { search: query, api_key: ENV['HARVESTER_API_KEY']})
    end
  end
end
