module Repository
  class PreviewRecord
  	include Enrichable

    store_in collection: 'preview_records'
  end
end