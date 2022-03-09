# frozen_string_literal: true

# app/serializer/harvest_job_serializer.rb
class HarvestJobSerializer < ActiveModel::Serializer
  attributes %i[id start_time end_time records_count throughput user_id
               created_at updated_at duration status status_message
               parser_id version_id environment failed_records_count
               invalid_records_count harvest_schedule_id posted_records_count
               mode retried_records_count last_posted_record_id source_id]

  # attribute starting with _ does not get serialized via attributes eg :_type
  # that's why we had to explicity define the attribute here
  attribute :_type do
    object._type
  end

  has_many :failed_records
  has_many :invalid_records
  has_one  :harvest_failure
end
