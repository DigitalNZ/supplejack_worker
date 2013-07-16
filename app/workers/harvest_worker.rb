require "snippet"

class HarvestWorker < AbstractWorker
  include Sidekiq::Worker

  attr_reader :last_processed_record

  def perform(harvest_job_id)
    harvest_job_id = harvest_job_id["$oid"] if harvest_job_id.is_a?(Hash)

    @job_id = harvest_job_id

    begin
      parser = job.parser

      options = {}
      options[:limit] = job.limit.to_i if job.limit.to_i > 0
      options[:from] = parser.last_harvested_at if job.incremental? && parser.last_harvested_at

      job.start!

      parser.load_file
      parser_klass = parser.loader.parser_class
      parser_klass.environment = job.environment if job.environment.present?

      records = parser_klass.records(options)

      records.each_with_index do |record, i|
        next if job.index.present? and i < job.index  #skip records up to index
        @last_processed_record = record
        self.process_record(record, job)

        return if self.stop_harvest?
      end

      while not api_update_finished?
        break if stop_harvest?
        sleep(2)
      end
      
      job.enqueue_enrichment_jobs
      
    rescue StandardError, ScriptError => e
      job.build_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
    end
    
    job.finish!
  end

  def process_record(record, job)
    begin
      if record.deletable? and record.attributes[:internal_identifier].present?
        self.delete_from_api(record.attributes[:internal_identifier]) unless job.test?
        job.records_count += 1
      elsif record.valid?
        attributes = record.attributes.merge(job_id: job.id)
        self.post_to_api(attributes) unless job.test?
        job.records_count += 1
      else
        job.invalid_records.build(created_at: Time.now, raw_data: record.raw_data, error_messages: record.errors.full_messages)
      end
    rescue StandardError => e
      failed_record = job.failed_records.build(created_at: Time.now, exception_class: e.class, message: e.message, backtrace: e.backtrace[0..5])
      failed_record.raw_data = record.try(:raw_data) rescue nil
    end

    job.save
  end

  def post_to_api(attributes)
    ApiUpdateWorker.perform_async("/harvester/records.json", {record: attributes, required_sources: job.required_enrichments}, job.id)
  end

  def delete_from_api(identifier)
    ApiDeleteWorker.perform_async(identifier.first, job.id) if identifier.any?
  end

end
