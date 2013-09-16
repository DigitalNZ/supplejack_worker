class HarvestJob < AbstractJob

  field :limit,                 type: Integer, default: 0
  field :enrichments,           type: Array
  field :index,                 type: Integer
  field :mode,                  type: String, default: 'normal'

  after_create :enqueue, unless: :preview?

  validates_uniqueness_of :parser_id, scope: [:environment, :status, :_type], if: :active?
  validates :mode, inclusion: ['normal', 'full_and_flush', 'incremental']

  def enqueue
    HarvestWorker.perform_async(self.id.to_s)
  end

  def enqueue_enrichment_jobs
    self.parser.enrichment_definitions.each do |name, options|
      EnrichmentJob.create_from_harvest_job(self, name) if Array(self.enrichments).include?(name.to_s)
    end
  end

  def flush_old_records
    begin
      RestClient.post("#{ENV['API_HOST']}/harvester/records/flush.json", {source_id: self.source_id, job_id: self.id})
    rescue RestClient::Exception => e
      self.build_harvest_failure(exception_class: e.class, message: "Flush old records failed with the following error mesage: #{e.message}", backtrace: e.backtrace[0..30])
    end
  end

  def records(&block)
    start!
    
    begin
      options = {}
      options[:limit] = limit.to_i if limit.to_i > 0
      options[:from] = parser.last_harvested_at if incremental? && parser.last_harvested_at

      parser.load_file
      parser_klass = parser.loader.parser_class
      parser_klass.environment = environment if environment.present?

      parser_klass.records(options).each_with_index do |record, index|
        yield record, index
      end
    rescue StandardError, ScriptError => e
      build_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
    end
  end

  def source_id
    if self.parser.loader.loaded?
      self.parser.loader.parser_class.get_source_id
    end
  end

  def finish!
    flush_old_records if full_and_flush? and limit.to_i == 0 and not harvest_failure?
    super
  end

  def full_and_flush?
    mode == 'full_and_flush'
  end

  def incremental?
    mode == 'incremental'
  end
end