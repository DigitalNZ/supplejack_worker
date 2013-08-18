require "snippet"

class PreviewWorker < HarvestWorker

	attr_reader :preview_id

	def perform(harvest_job_id, preview_id)
		@job_id = sanitize_id(harvest_job_id)
		@preview_id = sanitize_id(preview_id)

		preview.update_attribute(:status, "Worker starting. Loading parser and fetching data...")
		
		job.records do |record, i|
			next if i < job.index
			process_record(record)
			enrich_record(record)
		end

		preview.update_attribute(:harvest_failure, job.harvest_failure.to_json) if job.harvest_failure.present?
	end

	protected

	def strip_ids(hash)
		return nil if hash.nil?
		hash.delete('_id')
		hash.delete('record_id')
		hash.each do |key, value|
			if value.class == Hash
				value = strip_ids(value)
			elsif value.class == Array
				value.each do |array_value|
					array_value = strip_ids(array_value) if array_value.class == Hash
				end
			end
		end
		hash
	end

	def preview
		@preview ||= Preview.find(self.preview_id)
	end

	def validation_errors(record)
		!!record ? record.errors.map { |a, m| { a => m } } : {}
	end

	def current_record_id
		job.reload.last_posted_record_id
	end

	def process_record(record)
		preview.update_attribute(:status, "Parser loaded and data fetched. Parsing raw data and checking harvest validations...")

		preview.raw_data = record.raw_data
		preview.harvested_attributes = record.attributes.to_json
		preview.deletable = record.deletable?
		preview.field_errors = record.field_errors.to_json
		preview.validation_errors = validation_errors(record).to_json unless record.valid?
		preview.save

		preview.update_attribute(:status, "Raw data parsing complete.")
	end

	def enrich_record(record)
		return if record.deletable? or not record.valid?
		preview.update_attribute(:status, "Posting preview record to API...")

		post_to_api(record.attributes, false)

		preview.update_attribute(:status, "Starting preview record enrichment...")

		job.parser.enrichment_definitions.each do |name, options|
			next if options.has_key?(:type)
			preview.update_attribute(:status, "Running enrichment \"#{name}\"...")
			enrichment_job = EnrichmentJob.create_from_harvest_job(job, name)
			enrichment_job.update_attribute(:record_id, current_record_id)
			worker = EnrichmentWorker.new
			worker.perform(enrichment_job.id)
		end

		preview.update_attribute(:status, "All enrichments complete.")
		preview.update_attribute(:status, "Fetching final preview record from API...")

		preview_record = Repository::PreviewRecord.where(record_id: current_record_id.to_i).first

		unless preview_record.nil?
			preview.update_attribute(:api_record, strip_ids(preview_record.attributes).to_json) 
			preview.update_attribute(:status, "Preview complete.")
		end
	end

end