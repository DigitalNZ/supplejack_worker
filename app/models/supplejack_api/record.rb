# frozen_string_literal: true
module SupplejackApi
  class Record < ActiveResource::Base
    self.site = 'http://192.168.0.204:3000/harvester'
    include Enrichable

    def self.find(query)
      super(:all, params: { search: query, api_key: ENV['HARVESTER_API_KEY']})
    end
  end
end
