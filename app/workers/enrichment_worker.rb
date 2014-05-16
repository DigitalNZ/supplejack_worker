# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class EnrichmentWorker < AbstractWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1
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

    job.start!
    setup_parser

    enrichment_class.before(job.enrichment)

    records.each do |record|
      break if stop_harvest?
      process_record(record)
    end

    while not api_update_finished?
      break if stop_harvest?
      sleep(2)
    end

    enrichment_class.after(job.enrichment)

    job.finish!
  end

  def records
    if job.record_id.nil?
      if job.harvest_job.present?
        Repository::Record.where("fragments.job_id" => job.harvest_job.id.to_s).no_timeout
      else
        Repository::Record.where("fragments.source_id" => job.parser.source.source_id).no_timeout
      end
    else
      klass = job.preview? ? Repository::PreviewRecord : Repository::Record
      klass.where(record_id: job.record_id, "fragments.source_id" => job.parser.source.source_id).no_timeout
    end
  end

  def process_record(record)
    job.increment_processed_count!

    measure = Benchmark.measure do
      begin
        enrichment = enrichment_class.new(job.enrichment, enrichment_options, record, @parser_class)
        return unless enrichment.enrichable?

        enrichment.set_attribute_values
      unless enrichment.errors.any?
        post_to_api(enrichment) unless job.test?
      else
        Airbrake.notify(StandardError.new("Enrichment Errors: #{enrichment.errors.inspect}"))
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
    klass = "HarvesterCore::#{enrichment_options[:type]}Enrichment"
    klass.constantize
  end

  def post_to_api(enrichment)
    enrichment.record_attributes.each do |record_id, attributes|
      attrs = attributes.merge(job_id: job.id.to_s)
      ApiUpdateWorker.perform_async("/harvester/records/#{record_id}/fragments.json", {fragment: attrs, required_fragments: job.required_enrichments}, job.id.to_s)
      job.increment_records_count!
    end
  end

end
