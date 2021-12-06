# frozen_string_literal: true

# app/workers/api_delete_worker.rb
class ApiDeleteWorker < AbstractWorker
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: 5, backtrace: true
  sidekiq_retry_in { 5.seconds }

  sidekiq_retries_exhausted do |msg|
    ElasticAPM.report_message(msg)

    job_id = msg['args'].last
    job = AbstractJob.find(job_id)

    job.inc(posted_records_count: 1)

    job.failed_records << FailedRecord.new(
      exception_class: msg['class'],
      message: msg['error_message'],
      backtrace: msg['error_backtrace'],
      raw_data: msg['args'].to_json
    )
  end

  def perform(identifier, job_id)
    @job_id = job_id
    response = JSON.parse(Api::Record.delete(identifier))

    process_response(response)
  end
end
