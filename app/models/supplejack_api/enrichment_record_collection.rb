# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/enrichment_record_collection.rb
  class EnrichmentRecordCollection < ActiveResource::Collection
    attr_accessor :pagination

    # This class lets us access the active resource response,
    # so that can add pagination detail to the record object

    def initialize(elements = [])
      @elements = elements.blank? ? [] : elements['records']
      @pagination = elements.blank? ? { page: 1, total_pages: 1 } : elements['meta']
    end
  end
end
