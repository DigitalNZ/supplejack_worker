module Repository
  class Record
    include Enrichable

    store_in collection: 'records'
  end
end