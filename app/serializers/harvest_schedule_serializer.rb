# frozen_string_literal: true

# app/serializers/harvest_schedule_serializer.rb
class HarvestScheduleSerializer < ActiveModel::Serializer
  attributes %i[
    id
    parser_id
    start_time
    cron
    frequency
    at_hour
    at_minutes
    offset
    environment
    next_run_at
    last_run_at
    recurrent
    mode
    enrichments
    status
  ]

  def at_hour
    object.at_hour.to_s.rjust(2, '0')
  end

  def at_minutes
    object.at_minutes.to_s.rjust(2, '0')
  end
end
