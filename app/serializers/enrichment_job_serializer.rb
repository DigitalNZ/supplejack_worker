# frozen_string_literal: true

# app/serializers/enrichment_job_serializer.rb
class EnrichmentJobSerializer < ActiveModel::Serializer
  attributes %i[id start_time end_time records_count throughput user_id
                created_at updated_at duration status status_message
                parser_id version_id environment posted_records_count
                enrichment processed_count record_id last_posted_record_id
                source_id]

  # attribute starting with _ does not get serialized via attributes eg :_type
  # that's why we had to explicity define the attribute here
  attribute :_type do
    object._type
  end
end
