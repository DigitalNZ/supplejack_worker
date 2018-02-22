# frozen_string_literal: true
module SupplejackApi
  class Record
    include Enrichable

    store_in collection: 'records'

    embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiRecord::RecordFragment'

    default_scope -> { where(:status.in => %w[active partial]) }
  end
end
