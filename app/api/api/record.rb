# frozen_string_literal: true

module Api
  class Record
    def self.flush(params)
      Api::Request.new(
        '/harvester/records/flush',
        params
      ).post
    end

    def self.put(record_id, params)
      Api::Request.new(
        "/harvester/records/#{record_id}",
        params
      ).put
    end

    def self.delete(id)
      Api::Request.new(
        '/harvester/records/delete',
        { id: id }
      ).put
    end
  end
end
