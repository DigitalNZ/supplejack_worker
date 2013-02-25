class HarvestJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_harvested, :throughput, :created_at, :duration, :status, :user_id, :parser_id, :version_id, :environment
  attributes :failed_records_count, :invalid_records_count

  has_many :failed_records
  has_many :invalid_records
end