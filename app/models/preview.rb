class Preview
  include Mongoid::Document
  include Mongoid::Timestamps

  field :raw_data, 						   type: String
  field :harvested_attributes,   type: String
  field :api_record, 					   type: String
  field :status, 							   type: String
  field :deletable,              type: Boolean
  field :field_errors,           type: String
  field :validation_errors,      type: String
  field :harvest_failure,        type: String
  field :harvest_job_errors,     type: String
  field :format, 								 type: String

  def clear_attributes
  	self.raw_data = nil
  	self.harvested_attributes = nil
  	self.api_record = nil
  	self.status = nil
  	self.deletable = nil
  	self.field_errors = nil
  	self.validation_errors = nil
  	self.harvest_failure = nil
  	self.harvest_job_errors = nil
  	self.save
  end

  def self.spawn_preview_worker(attributes)
  	job = HarvestJob.create(attributes[:harvest_job])
  	preview = Preview.create(format: attributes[:format], status: "Starting preview process")

  	unless job.valid?
  		harvest_job = HarvestJob.where(status: "active", parser_id: job.parser_id, environment: "preview").first
  		harvest_job.update_attribute(:status, "stopped")
  	end

  	PreviewWorker.perform_async(job.id.to_s, preview.id.to_s)

  	return preview
  end
end