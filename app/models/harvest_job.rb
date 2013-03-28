class HarvestJob < AbstractJob

  field :limit,                 type: Integer, default: 0
  field :incremental,           type: Boolean, default: false
  field :enrichments,           type: Array

  after_create :enqueue

  validates_uniqueness_of :parser_id, scope: [:environment, :status, :_type], if: :active?

  def enqueue
    HarvestWorker.perform_async(self.id)
  end

  def finish!
    super
    self.enqueue_enrichment_jobs
  end

  def enqueue_enrichment_jobs
    self.parser.enrichment_definitions.each do |name, options|
      EnrichmentJob.create_from_harvest_job(self, name) if Array(self.enrichments).include?(name.to_s)
    end
  end

end
