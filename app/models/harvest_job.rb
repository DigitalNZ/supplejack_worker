class HarvestJob < AbstractJob

  field :limit,                 type: Integer, default: 0
  field :enrichments,           type: Array
  field :index,                 type: Integer
  field :mode,                  type: String, default: 'normal'

  after_create :enqueue, unless: :preview?

  validates_uniqueness_of :parser_id, scope: [:environment, :status, :_type], message: I18n.t('job.already_running', type: 'Harvest'), if: :active?
  validates :mode, inclusion: ['normal', 'full_and_flush', 'incremental']

  def enqueue
    HarvestWorker.perform_async(self.id.to_s)
  end

  def enqueue_enrichment_jobs
    begin
      self.parser.enrichment_definitions(environment).each do |name, options|
        EnrichmentJob.create_from_harvest_job(self, name) if Array(self.enrichments).include?(name.to_s)
      end
    rescue StandardError, ScriptError => e
      self.create_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
      self.fail_job(e.message)
      Sidekiq.logger.error "Caught Exception. Message:#{e.message}, created harvest failure and failed job"
    end
  end

  def flush_old_records
    begin
      RestClient.post("#{ENV['API_HOST']}/harvester/records/flush.json", {source_id: self.source_id, job_id: self.id})
    rescue RestClient::Exception => e
      self.create_harvest_failure(exception_class: e.class, message: "Flush old records failed with the following error mesage: #{e.message}", backtrace: e.backtrace[0..30])
      self.fail_job(e.message)
    end
  end

  def records(&block)
    begin
      start! unless self.active?

      options = {}
      options[:limit] = limit.to_i if limit.to_i > 0
      options[:from] = parser.last_harvested_at if incremental? && parser.last_harvested_at

      parser.load_file(environment)
      parser_klass = parser.loader.parser_class
      parser_klass.environment = environment if environment.present?

      parser_klass.records(options).each_with_index do |record, index|
        yield record, index
      end
    rescue StandardError, ScriptError => e
      self.create_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
      self.fail_job(e.message)
    end
  end

  def source_id
    self.parser.source.source_id
  end

  def finish!
    flush_old_records if full_and_flush? and limit.to_i == 0 and not harvest_failure? and not stopped?
    super
  end

  def full_and_flush?
    mode == 'full_and_flush'
  end

  def incremental?
    mode == 'incremental'
  end
end
