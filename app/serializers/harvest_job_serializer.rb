# frozen_string_literal: true

# app/serializer/harvest_job_serializer.rb
class HarvestJobSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :records_count, :throughput
  attributes :created_at, :duration, :status, :status_message, :user_id, :parser_id, :version_id, :environment
  attributes :failed_records_count, :invalid_records_count, :harvest_schedule_id,
             :mode, :posted_records_count, :retried_records_count, :last_posted_record_id

  # attribute starting with _ does not get serialized via attributes eg :_type
  # that's why we had to explicity define the attribute here
  attribute :_type do
    object._type
  end

  has_many :failed_records
  has_many :invalid_records
  has_one :harvest_failure
end
