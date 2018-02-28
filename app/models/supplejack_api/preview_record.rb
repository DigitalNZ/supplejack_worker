# frozen_string_literal: true
module SupplejackApi
  class PreviewRecord
    include Enrichable

    store_in collection: 'preview_records'
  end
end
