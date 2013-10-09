class HarvestJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_count, :throughput, :_type
  attributes :created_at, :duration, :status, :status_message, :user_id, :parser_id, :version_id, :environment
  attributes :failed_records_count, :invalid_records_count, :harvest_schedule_id, :mode, :posted_records_count

  has_many :failed_records
  has_many :invalid_records
  has_one :harvest_failure
end