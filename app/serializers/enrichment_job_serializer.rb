class EnrichmentJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_count, :throughput, :_type
  attributes :created_at, :duration, :status, :user_id, :parser_id, :version_id, :environment, :enrichment
  attributes :posted_records_count, :record_id
end