# frozen_string_literal: true

module Api
  class Source
    def self.get(source_id)
      Api::Request.new(
        "/harvester/sources/#{source_id}"
      ).get
    end

    def self.put(source_id, params)
      Api::Request.new(
        "/harvester/sources/#{source_id}",
        params
      ).put
    end

    def self.link_check_records(source_id)
      Api::Request.new(
        "/harvester/sources/#{source_id}/link_check_records"
      ).get
    end
  end
end
