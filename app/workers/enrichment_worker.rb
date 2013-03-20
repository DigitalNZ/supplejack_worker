class EnrichmentWorker
  include Sidekiq::Worker

  attr_reader :parser, :parser_class
    
  def perform(enrichment_job_id)
    @enrichment_job_id = enrichment_job_id

    enrichment_job.start!
    setup_parser

    records.each do |record|
      break if stop_harvest?
      process_record(record)
    end

    enrichment_job.finish!
  end

  def enrichment_job
    @enrichment_job ||= EnrichmentJob.find(@enrichment_job_id)
  end

  def records
    DnzApi::Record.where("sources.source_id" => @parser_class.get_source_id)
  end

  def process_record(record)
    begin
      enrichment = HarvesterCore::Enrichment.new(enrichment_job.enrichment, enrichment_block, record, @parser_class)
      enrichment.set_attribute_values
      post_to_api(enrichment) unless enrichment_job.test?
      enrichment_job.increment_records_count!
    rescue RestClient::ResourceNotFound => e
      Rails.logger.info "Resource Not Found: #{enrichment.try(:_url)}"
    rescue StandardError => e
      Rails.logger.info "\n#{e.message}, #{e.class.inspect}"
      e.backtrace.each {|b| Rails.logger.info b }
    end
  end

  private

  def setup_parser
    @parser = enrichment_job.parser
    @parser.load_file
    @parser_class = @parser.loader.parser_class
    @parser_class.environment = enrichment_job.environment
  end

  def enrichment_block
    @parser.enrichment_definitions[enrichment_job.enrichment.to_sym]
  end

  def post_to_api(enrichment)
    record = enrichment.record
    attributes = enrichment.attributes

    measure = Benchmark.measure do
      RestClient.post "#{ENV["API_HOST"]}/harvester/records/#{record.id}/sources.json", {source: attributes}.to_json, :content_type => :json, :accept => :json
    end

    puts "POST (#{measure.real.round(4)}): #{enrichment._url}" unless Rails.env.test?
  end

  def stop_harvest?
    enrichment_job.reload
    enrichment_job.stopped?
  end
end