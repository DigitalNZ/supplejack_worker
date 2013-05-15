class Preview

	attr_reader :parser_code, :index, :environment, :parser_id, :user_id

	attr_reader :harvest_job, :last_processed_record, :record

	def initialize(attributes = {})
		@parser_code = attributes[:parser_code]
		@index = attributes[:index].to_i || 0
		@environment = "staging"
		@parser_id = attributes[:parser_id]
		@user_id = attributes[:user_id]
	end


	def as_json
		process_record
		{
			record: strip_ids(@record.try(:attributes)),
			raw_data: @last_processed_record.try(:raw_data),
			harvested_attributes: @last_processed_record.try(:attributes),
			harvest_job_id: @harvest_job.id,
			errors: {
				field_errors: field_errors,
				validation_errors: validation_errors,
				harvest_failure: @harvest_job.harvest_failure.as_json
			},
		}
	end

	private

	def validation_errors
		!!@last_processed_record ? @last_processed_record.errors.map { |a, m| { a => m } } : {}
	end

	def field_errors
		!!@last_processed_record ? @last_processed_record.field_errors : {}
	end

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

	def process_record
		@harvest_job = HarvestJob.create(user_id: self.user_id, 
											environment: "preview", 
											index: self.index,
											limit: self.index + 1,
											parser_id: self.parser_id, 
											parser_code: self.parser_code)

		harvest_worker = HarvestWorker.new

		harvest_worker.perform(@harvest_job.id)

		unless @harvest_job.reload.harvest_failure?
			@last_processed_record = harvest_worker.last_processed_record
			record_id = @harvest_job.reload.last_posted_record_id

			if @last_processed_record.valid? 

				@harvest_job.parser.enrichment_definitions.each do |name, options|
					next if options.has_key?(:type)
					job = EnrichmentJob.create_from_harvest_job(@harvest_job, name)
					job.update_attribute(:record_id, record_id)
					worker = EnrichmentWorker.new
					worker.perform(job.id)
				end

				@record = Repository::PreviewRecord.where(record_id: record_id.to_i).first
			end
		end
	end
end