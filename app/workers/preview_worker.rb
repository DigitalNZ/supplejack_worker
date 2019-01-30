# frozen_string_literal: true

require 'snippet'

# app/workers/preview_worker.rb
class PreviewWorker < HarvestWorker
  sidekiq_options retry: 1, queue: 'critical'
  sidekiq_retry_in { 1 }

  attr_reader :preview_id

  sidekiq_retries_exhausted do |msg|
    job_id = msg['args'].first
    preview_id = msg['args'].last

    job = AbstractJob.find(job_id)
    job.update_attribute(:end_time, Time.zone.now)
    job.update_attribute(:status_message, "Failed with exception #{msg['error_message']}")
    job.error!

    preview = Preview.find(preview_id)
    preview.update_attribute(:status, "Preview failed. Harvest Job id:#{job_id}, Preview id:#{preview_id}. Exception: #{msg['error_message']}")

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      status: "Preview failed. Harvest Job id:#{job_id}, Preview id:#{preview_id}. Exception: #{msg['error_message']}"
    )

    Sidekiq.logger.warn "Preview #{preview_id} FAILED with exception #{msg['error_message']}"
  end

  def perform(harvest_job_id, preview_id)
    @job_id = sanitize_id(harvest_job_id)
    @preview_id = sanitize_id(preview_id)

    preview.update_attribute(:status, 'Worker starting. Loading parser and fetching data...')

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      status: 'Worker starting. Loading parser and fetching data...'
    )

    unless stop_harvest?
      job.records do |record, i|
        next if i < job.index

        process_record(record)
        enrich_record(record)
      end
    end

    job.finish!

    preview.update_attribute(:harvest_failure, job.harvest_failure.to_json) if job.harvest_failure.present?

    return if job.harvest_failure.blank?

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      harvest_failure: job.harvest_failure.to_json
    )
  end

  protected

  def strip_ids(hash)
    return nil if hash.nil?

    hash.delete('_id')
    hash.delete('record_id')
    hash.each do |_key, value|
      if value.class == Hash
        strip_ids(value)
      elsif value.class == Array
        value.each do |array_value|
          strip_ids(array_value) if array_value.class == Hash
        end
      end
    end
    hash
  end

  def preview
    @preview ||= Preview.find(preview_id)
  end

  def validation_errors(record)
    !!record ? record.errors.map { |a, m| { a => m } } : {}
  end

  def current_record_id
    job.reload.last_posted_record_id
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def process_record(record)
    preview.update_attribute(:status, 'Parser loaded and data fetched. Parsing raw data and checking harvest validations...')

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      status: 'Parser loaded and data fetched. Parsing raw data and checking harvest validations...'
    )

    record.attributes.merge!(source_id: job.parser.source.source_id, data_type: job.parser.data_type)

    preview.raw_data = record.raw_data
    preview.harvested_attributes = record.attributes.to_json
    preview.deletable = record.deletable?
    preview.field_errors = record.field_errors.to_json
    preview.validation_errors = validation_errors(record).to_json unless record.valid?
    preview.save!

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      raw_data: preview.raw_output,
      harvested_attributes: CodeRay.scan(preview.harvested_attributes_json, :json).html(line_numbers: :table).html_safe,
      deletable: record.deletable?,
      status: 'Raw data parsing complete.'
    )

    if preview.field_errors?
      ActionCable.server.broadcast("#{job.environment}_channel_#{job.parser_id}_#{job.user_id}", field_errors: preview.field_errors_output)
    end

    if preview.validation_errors?
      ActionCable.server.broadcast("#{job.environment}_channel_#{job.parser_id}_#{job.user_id}", validation_errors: validation_errors(record).to_json)
    end

    if preview.harvest_job_errors?
      ActionCable.server.broadcast(
        "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
        harvest_job_errors: preview.harvest_job_errors_output
      )
    end

    preview.update_attribute(:status, 'Raw data parsing complete.')
  end
  # rubocop:enable Metrics/MethodLength:
  # rubocop:enable Metrics/AbcSize:

  # rubocop:disable Metrics/MethodLength:
  # rubocop:disable Metrics/AbcSize:
  def enrich_record(record)
    return if record.deletable? || !record.valid?

    preview.update_attribute(:status, 'Posting preview record to API...')

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      api_record: preview.api_record_output,
      status: 'Posting preview record to API...'
    )

    post_to_api(record.attributes, false)

    preview.update_attribute(:status, 'Starting preview record enrichment...')

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      api_record: preview.api_record_output,
      status: 'Starting preview record enrichment...'
    )

    job.parser.enrichment_definitions(:preview).each do |name, options|
      next if options.key?(:type)

      preview.update_attribute(:status, "Running enrichment \"#{name}\"...")

      ActionCable.server.broadcast(
        "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
        api_record: preview.api_record_output,
        status: "Running enrichment #{name}"
      )

      enrichment_job = EnrichmentJob.create_from_harvest_job(job, name)
      enrichment_job.update_attribute(:record_id, current_record_id)
      worker = EnrichmentWorker.new
      worker.perform(enrichment_job.id)
    end

    preview.update_attribute(:status, 'All enrichments complete.')
    preview.update_attribute(:status, 'Fetching final preview record from API...')

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      api_record: preview.api_record_output,
      status: 'All enrichments complete'
    )

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      api_record: preview.api_record_output,
      status: 'Fetching final preview record from API...'
    )

    preview_record = SupplejackApi::PreviewRecord.find(record_id: current_record_id.to_i).first

    return if preview_record.nil?

    preview.update_attribute(:api_record, strip_ids(preview_record.attributes).to_json)
    preview.update_attribute(:status, 'Preview complete.')

    ActionCable.server.broadcast(
      "#{job.environment}_channel_#{job.parser_id}_#{job.user_id}",
      api_record: preview.api_record_output,
      status: 'Preview complete.'
    )
  end
  # rubocop:enable Metrics/MethodLength:
  # rubocop:enable Metrics/AbcSize:
end
