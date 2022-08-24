# frozen_string_literal: true

# app/serializers/enrichment_job_serializer.rb
class EnrichmentJobSerializer < AbstractJobSerializer
  attributes %i[
    enrichment
    enrichment_failure
    record_id
  ]
end
