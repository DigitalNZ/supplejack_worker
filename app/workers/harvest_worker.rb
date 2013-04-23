require "snippet"

class HarvestWorker < AbstractWorker
  include Sidekiq::Worker

  def perform(harvest_job_id)
    harvest_job_id = harvest_job_id["$oid"] if harvest_job_id.is_a?(Hash)

    job = HarvestJob.find(harvest_job_id)

    begin
      parser = job.parser

      options = {}
      options[:limit] = job.limit.to_i if job.limit.to_i > 0
      options[:from] = parser.last_harvested_at if job.incremental && parser.last_harvested_at

      job.start!

      parser.load_file
      parser_klass = parser.loader.parser_class
      parser_klass.environment = job.environment if job.environment.present?

      records = parser_klass.records(options)
      records.each do |record|
        self.process_record(record, job)
        return if self.stop_harvest?(job)
      end
    rescue StandardError => e
      job.build_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
    end

    job.finish!
  end

  def process_record(record, job)
    begin
      if record.valid?
        self.post_to_api(record) unless job.test?
        job.records_count += 1
      else
        job.invalid_records.build(raw_data: record.full_raw_data, error_messages: record.errors.full_messages)
      end
    rescue StandardError => e
      failed_record = job.failed_records.build(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..5])
      failed_record.raw_data = record.try(:raw_data) rescue nil
    end

    job.save
  end

  def post_to_api(record)
    attributes = record.attributes

    measure = Benchmark.measure do
      RestClient.post "#{ENV["API_HOST"]}/harvester/records.json", {record: attributes}.to_json, :content_type => :json, :accept => :json
    end

    puts "HarvestJob: POST (#{measure.real.round(4)}): #{attributes[:identifier].try(:first)}" unless Rails.env.test?
  end

end
