# frozen_string_literal: true

# app/serializers/enrichment_job_serializer.rb
class EnrichmentJobSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :end_time, :records_count, :throughput
  attributes :created_at, :duration, :status, :status_message, :user_id, :parser_id, :version_id, :environment, :enrichment
  attributes :posted_records_count, :processed_count, :record_id, :last_posted_record_id

  # attribute starting with _ does not get serialized via attributes eg :_type
  # that's why we had to explicity define the attribute here
  attribute :_type do
    object._type
  end
end
