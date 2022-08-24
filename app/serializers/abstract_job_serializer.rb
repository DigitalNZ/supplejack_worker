# frozen_string_literal: true

# app/serializer/harvest_job_serializer.rb
class AbstractJobSerializer < ActiveModel::Serializer
  attributes %i[
    id
    updated_at
    created_at

    start_time
    end_time

    records_count
    throughput
    duration
    status
    status_message

    user_id
    parser_id
    source_id
    version_id
    environment
    harvest_schedule_id

    invalid_records_count
    failed_records_count
    posted_records_count
    retried_records_count

    processed_count
    last_posted_record_id
  ]

  # attribute starting with _ does not get serialized via attributes eg :_type
  # that's why we had to explicity define the attribute here
  attribute :_type do
    object._type
  end

  has_many :failed_records
  has_many :invalid_records
  has_one :harvest_failure
end
