# frozen_string_literal: true

# app/serializer/harvest_job_serializer.rb
class HarvestJobSerializer < AbstractJobSerializer
  attributes %i[
    mode
  ]
end
