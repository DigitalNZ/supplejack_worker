module Repository
  class Record
    include Enrichable

    store_in collection: 'records'

    default_scope where(:status.in => ["active", "partial"])
  end
end