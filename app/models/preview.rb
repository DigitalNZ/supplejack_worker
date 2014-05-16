# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

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

  def self.spawn_preview_worker(attributes)
  	job = HarvestJob.create(attributes[:harvest_job])
  	preview = Preview.create(format: attributes[:format], status: "New preview record initialised. Waiting in queue...")

  	unless job.valid?
  		harvest_job = HarvestJob.where(status: "active", parser_id: job.parser_id, environment: "preview").first
  		harvest_job.stop!
      job.save!
  	end

  	PreviewWorker.perform_async(job.id.to_s, preview.id.to_s)

  	return preview
  end
end