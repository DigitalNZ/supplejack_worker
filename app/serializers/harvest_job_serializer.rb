class HarvestJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_harvested, :average_record_time, :created_at, :duration, :status, :user_id, :parser_id, :environment

  has_many :harvest_job_errors
end