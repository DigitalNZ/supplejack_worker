class EnrichmentJob < AbstractJob
  
  belongs_to :harvest_job

  after_create :enqueue, unless: :preview?

  field :enrichment,  type: String
  field :record_id,   type: Integer

  validates_uniqueness_of :enrichment, scope: [:environment, :status, :_type, :parser_id], if: :active?

  def self.create_from_harvest_job(job, enrichment)
    self.create(parser_id:      job.parser_id,
                version_id:     job.version_id,
                user_id:        job.user_id,
                environment:    job.environment,
                harvest_job_id: job.id,
                enrichment:     enrichment)
  end

  def enqueue
    EnrichmentWorker.perform_async(self.id)
  end
end