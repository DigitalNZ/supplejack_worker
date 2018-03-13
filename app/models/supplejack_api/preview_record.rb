# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/preview_record.rb
  class PreviewRecord
    include Enrichable

    store_in collection: 'preview_records'
  end
end
