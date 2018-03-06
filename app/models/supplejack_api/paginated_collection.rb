module SupplejackApi
  class EnrichmentRecordCollection < ActiveResource::Collection
    attr_accessor :pagination

    def initialize(elements = [])
      @elements = elements['records']
      @pagination = elements['meta']
    end
  end
end
