# frozen_string_literal: true

# app/workers/enrichment_worker.rb
class EnrichmentWorker < AbstractWorker
  include Sidekiq::Job
  sidekiq_options retry: 5, queue: 'default'

  sidekiq_retries_exhausted do |msg, e|
    job_id = msg['args'].first
    job = AbstractJob.find(job_id)
    job.update_attribute(:end_time, Time.zone.now)
    job.create_enrichment_failure(
      exception_class: e.class,
      message: e.message,
      backtrace: e.backtrace && e.backtrace[0..30]
    )
    job.fail_job("Failed with exception #{msg['error_message']}")

    Sidekiq.logger.warn "EnrichmentJob #{job_id} FAILED with exception #{msg['error_message']}"
  end

  ENRICH_STATUS = { 'status' => 'active' }

  attr_reader :parser, :parser_class

  # rubocop:disable Metrics/MethodLength
  def perform(enrichment_job_id)
    @job_id = enrichment_job_id.to_s

    job.start! if job.may_start?
    setup_parser

    enrichment_class.before(job.enrichment)

    if job.states.any?
      records = fetch_records(job.states.last.page.to_i)
    else
      records = fetch_records(1)
      job.states.create!(page: 1)
    end

    return job.finish! if records.blank?

    while more_records?(records)
      records.each do |record|
        break if stop_harvest?

        process_record(record)
      end

      break if last_page_records?(records)

      records = fetch_records(records.pagination['page'] + 1)
      job.states.create!(page: records.pagination['page']) unless stop_harvest?
    end

    until api_update_finished?
      break if stop_harvest?
      sleep(2)
    end

    enrichment_class.after(job.enrichment)

    job.finish! unless job.stopped?
  end
  # rubocop:enable Metrics/MethodLength

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
      query = if job.harvest_job.present?
        { 'fragments.job_id' => job.harvest_job.id.to_s }
      else
        { 'fragments.source_id' => job.parser.source.source_id }
      end

      SupplejackApi::Record.find(query.merge(ENRICH_STATUS), page:)
    else
      klass = job.preview? ? SupplejackApi::PreviewRecord : SupplejackApi::Record
      klass.find({ record_id: job.record_id }.merge(ENRICH_STATUS), page:)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def process_record(record)
    job.increment_processed_count!

    measure = Benchmark.measure do
      enrichment = enrichment_class.new(job.enrichment, enrichment_options, record, @parser_class)
      return unless enrichment.enrichable?

      enrichment.set_attribute_values
      if enrichment.errors.any?
        job.create_enrichment_failure(
          exception_class: 'AttributeError',
          message: 'Exception raised in attribute blocks',
          backtrace: enrichment.errors.map { |attr, errors| errors.map { |error| "#{attr}: #{error}" } }.flatten
        )
        ElasticAPM.report(StandardError.new('Enrichment Error'))
        ElasticAPM.report_message("Enrichment Errors on #{enrichment_class} in Parser:
          #{@parser.id}. Backtrace:
          #{{
            enrichment: enrichment.errors.inspect,
            job: job.inspect, options:
            enrichment_options.inspect,
            record: record.inspect,
            parser: @parser.id }}")
      else
        post_to_api(enrichment) unless job.test?
      end
    end

    Rails.logger.debug "EnrichmentJob: PROCESS RECORD (#{measure.real.round(4)})" unless Rails.env.test?
  rescue RestClient::ResourceNotFound => e
    ElasticAPM.report(e)
    ElasticAPM.report_message("Resource Not Found: #{enrichment.inspect}, this is occuring on #{job.enrichment} inside of #{@parser.id}")

  rescue StandardError => e
    job.create_enrichment_failure(
      exception_class: e.class,
      message: e.message,
      backtrace: e.backtrace[0..30]
    )
    ElasticAPM.report(e)
    ElasticAPM.report_message("
      The enrichment #{job.enrichment} is erroring inside of parser #{@parser.id}. Backtrace:
      #{e.backtrace}
    ")
  end
  # rubocop:enable Metrics/MethodLength

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

        ApiUpdateWorker.perform_async(
          "/harvester/records/#{mongo_record_id}/fragments.json", {
            fragment: attrs,
            required_fragments: job.required_enrichments
          }.as_json,
          job.id.to_s
        )
        job.increment_records_count!
      end
    end
end
