class HarvestJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_harvested, :average_record_time, :created_at

  has_many :harvest_job_errors
end