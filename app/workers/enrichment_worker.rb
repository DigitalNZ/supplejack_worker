# frozen_string_literal: true

# app/workers/enrichment_worker.rb
class EnrichmentWorker < AbstractWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: 'default'
  sidekiq_retry_in { 1 }

  sidekiq_retries_exhausted do |msg|
    job_id = msg['args'].first
    job = AbstractJob.find(job_id)
    job.update_attribute(:status_message, "Failed with exception #{msg['error_message']}")
    job.error!

    Sidekiq.logger.warn "EnrichmentJob #{job_id} FAILED with exception #{msg['error_message']}"
  end

  attr_reader :parser, :parser_class

  def perform(enrichment_job_id)
    @job_id = enrichment_job_id.to_s

    job.start! if job.may_start?
    setup_parser

    enrichment_class.before(job.enrichment)

    records = fetch_records(1)

    while more_records?(records)
      records.each do |record|
        break if stop_harvest?

        process_record(record)
      end

      break if last_page_records?(records)

      records = fetch_records(records.pagination['page'] + 1)
    end

    until api_update_finished?
      break if stop_harvest?
      sleep(2)
    end

    enrichment_class.after(job.enrichment)

    job.finish!
  end

  def more_records?(records)
    return true if job.preview?
    records.pagination['page'] <= records.pagination['total_pages']
  end

  def last_page_records?(records)
    return true if job.preview?
    records.pagination['page'] == records.pagination['total_pages']
  end

  def fetch_records(page = 0)
    if job.record_id.nil?
      if job.harvest_job.present?
        SupplejackApi::Record.find({ 'fragments.job_id' => job.harvest_job.id.to_s }, page: page)

      else
        SupplejackApi::Record.find({ 'fragments.source_id' => job.parser.source.source_id }, page: page)
      end
    else
      klass = job.preview? ? SupplejackApi::PreviewRecord : SupplejackApi::Record
      klass.find({ record_id: job.record_id, 'fragments.source_id' => job.parser.source.source_id }, page: page)
    end
  end

  def process_record(record)
    job.increment_processed_count!

    measure = Benchmark.measure do
      begin
        enrichment = enrichment_class.new(job.enrichment, enrichment_options, record, @parser_class)
        return unless enrichment.enrichable?

        enrichment.set_attribute_values
        if enrichment.errors.any?
          Airbrake.notify(StandardError.new("Enrichment Errors: #{enrichment.errors.inspect}"))
          # rubocop:disable Metrics/LineLength
          Sidekiq.logger.error "Enrichment Errors on #{enrichment_class}: #{enrichment.errors.inspect} \n JOB: #{job.inspect} \n OPTIONS: #{enrichment_options.inspect}, RECORD: #{record.inspect} \n PARSER CLASS: #{@parser_class.inspect}"
          # rubocop:enable Metrics/LineLength
        else
          post_to_api(enrichment) unless job.test?
        end
      rescue RestClient::ResourceNotFound => e
        Airbrake.notify(e, error_message: "Resource Not Found: #{enrichment.inspect}")
      rescue StandardError => e
        Airbrake.notify(e)
      end
    end
    Rails.logger.debug "EnrichmentJob: PROCESS RECORD (#{measure.real.round(4)})" unless Rails.env.test?
  end

  private

  def setup_parser
    @parser = job.parser
    @parser.load_file(job.environment)
    @parser_class = @parser.loader.parser_class
    @parser_class.environment = job.environment
  end

  def enrichment_options
    @enrichment_options ||= @parser.enrichment_definitions(job.environment)[job.enrichment.to_sym]
  end

  def enrichment_class
    klass = "SupplejackCommon::#{enrichment_options[:type]}Enrichment"
    klass.constantize
  end

  def post_to_api(enrichment)
    enrichment.record_attributes.as_json.each do |mongo_record_id, attributes|
      attrs = attributes.merge(job_id: job.id.to_s)
      # rubocop:disable Metrics/LineLength
      ApiUpdateWorker.perform_async("/harvester/records/#{mongo_record_id}/fragments.json", { fragment: attrs, required_fragments: job.required_enrichments }, job.id.to_s)
      # rubocop:enable Metrics/LineLength
      job.increment_records_count!
    end
  end
end
