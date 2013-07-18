class EnrichmentWorker < AbstractWorker
  include Sidekiq::Worker

  attr_reader :parser, :parser_class
    
  def perform(enrichment_job_id)
    @job_id = enrichment_job_id

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
        Repository::Record.where("sources.job_id" => job.harvest_job.id.to_s).no_timeout
      else
        Repository::Record.where("sources.source_id" => @parser_class.get_source_id).no_timeout
      end
    else
      klass = job.preview? ? Repository::PreviewRecord : Repository::Record
      klass.where(record_id: job.record_id, "sources.source_id" => @parser_class.get_source_id).no_timeout
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
        Rails.logger.info "Enrichment Errors: #{enrichment.errors.inspect}"
      end

      rescue RestClient::ResourceNotFound => e
        Rails.logger.info "Resource Not Found: #{enrichment.inspect}"
      rescue StandardError => e
        Rails.logger.info "\n#{e.message}, #{e.class.inspect}"
        e.backtrace.each {|b| Rails.logger.info b }
      end
    end
    puts "EnrichmentJob: PROCESS RECORD (#{measure.real.round(4)})" unless Rails.env.test?
  end

  private

  def setup_parser
    @parser = job.parser
    @parser.load_file
    @parser_class = @parser.loader.parser_class
    @parser_class.environment = job.environment
  end

  def enrichment_options
    @enrichment_options ||= @parser.enrichment_definitions[job.enrichment.to_sym]
  end

  def enrichment_class
    klass = "HarvesterCore::#{enrichment_options[:type]}Enrichment"
    klass.constantize
  end

  def post_to_api(enrichment)
    enrichment.record_attributes.each do |record_id, attributes|
      attrs = attributes.merge(job_id: job.id.to_s)
      ApiUpdateWorker.perform_async("/harvester/records/#{record_id}/sources.json", {source: attrs, required_sources: job.required_enrichments}, job.id.to_s)
      job.increment_records_count!
    end
  end

end