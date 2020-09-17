# frozen_string_literal: true

require 'snippet'

# app/workers/harvest_worker.rb
class HarvestWorker < AbstractWorker
  include Sidekiq::Worker
  include Matcher::ConceptMatcher
  
  sidekiq_options retry: 5, backtrace: true, queue: 'default', lock: :until_expired, lock_ttl: 5.minutes, on_conflict: :log

  sidekiq_retries_exhausted do |msg|
    job_id = msg['args'].first
    job = AbstractJob.find(job_id)
    job.update_attribute(:end_time, Time.zone.now)
    job.update_attribute(:status_message, "Failed with exception #{msg['error_message']}")
    job.error!

    Sidekiq.logger.warn "HarvestJob #{job_id} FAILED with exception #{msg['error_message']}"
  end

  def perform(harvest_job_id)
    @job_id = harvest_job_id.is_a?(Hash) ? harvest_job_id['$oid'] : harvest_job_id
    @source_id = job.parser.source.source_id

    job.records do |record, _i|
      process_record(record, job)
      break if stop_harvest?
    end

    until api_update_finished?
      break if stop_harvest?
      sleep(2)
    end

    job.finish! unless job.stopped?

    job.enqueue_enrichment_jobs
  end

  def process_record(record, job)
    begin
      if record.deletable? && record.attributes[:internal_identifier].present?
        delete_from_api(record.attributes[:internal_identifier]) unless job.test?
        job.records_count += 1
      elsif record.valid?
        attributes = record.attributes.merge(job_id: job.id.to_s, source_id: @source_id, data_type: job.parser.data_type)

        if job.parser.record? || (job.parser.concept? && attributes[:match_concepts].present? &&
            create_concept?(attributes))

          post_to_api(attributes) unless job.test?
          job.records_count += 1
        end
      else
        job.invalid_records.build(created_at: Time.zone.now, raw_data: record.raw_data, error_messages: record.errors.full_messages)
      end
    rescue StandardError => e
      failed_record = job.failed_records.build(created_at: Time.zone.now, exception_class: e.class, message: e.message, backtrace: e.backtrace[0..5])
      failed_record.raw_data = begin
                                 record.try(:raw_data)
                               rescue StandardError
                                 nil
                               end
      Airbrake.notify(e, error_message: "The Parser #{job.parser.id} has an error in it", backtrace: e.backtrace)
    end

    job.save!
  end

  def post_to_api(attributes, async = true)
    data_type = begin
                  attributes.delete(:data_type).downcase.to_sym
                rescue StandardError
                  :record
                end
    path = "/harvester/#{data_type.to_s.pluralize}.json"

    attributes.delete(:data_type)
    attributes.delete(:match_concepts)

    if async
      ApiUpdateWorker.perform_async(path, { data_type => attributes, required_fragments: job.required_enrichments }, job.id.to_s)
    else
      api_update_worker = ApiUpdateWorker.new
      api_update_worker.perform(path, { data_type => attributes, required_fragments: job.required_enrichments }, job.id.to_s)
    end
  end

  def delete_from_api(identifier)
    ApiDeleteWorker.perform_async(identifier.first, job.id.to_s) if identifier.any?
  end
end
