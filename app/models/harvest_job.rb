class HarvestJob < AbstractJob

  field :limit,                 type: Integer, default: 0
  field :enrichments,           type: Array
  field :index,                 type: Integer
  field :mode,                  type: String, default: 'normal'

  after_create :enqueue, unless: :preview?

  validates_uniqueness_of :parser_id, scope: [:environment, :status, :_type], if: :active?
  validates :mode, inclusion: ['normal', 'full_and_flush', 'incremental']

  def enqueue
    HarvestWorker.perform_async(self.id)
  end

  def enqueue_enrichment_jobs
    self.parser.enrichment_definitions.each do |name, options|
      EnrichmentJob.create_from_harvest_job(self, name) if Array(self.enrichments).include?(name.to_s)
    end
  end

  def flush_old_records
    RestClient.post("#{ENV['API_HOST']}/harvester/records/flush.json", {source_id: self.source_id, job_id: self.id})
  end

  def source_id
    if self.parser.loader.loaded?
      self.parser.loader.parser_class.get_source_id
    end
  end

  def finish!
    flush_old_records if full_and_flush? and limit.to_i == 0
    super
  end

  def full_and_flush?
    mode == 'full_and_flush'
  end

  def incremental?
    mode == 'incremental'
  end
end