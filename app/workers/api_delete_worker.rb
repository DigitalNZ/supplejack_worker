# frozen_string_literal: true
class ApiDeleteWorker < AbstractWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 5, backtrace: true
  sidekiq_retry_in { 5.seconds }

  sidekiq_retries_exhausted do |msg|
    Airbrake.notify(msg)

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
    response = RestClient.put(
      "#{ENV['API_HOST']}/harvester/records/delete",
      { id: identifier, api_key: ENV['HARVESTER_API_KEY'] },
      content_type: :json, accept: :json
    )
    response = JSON.parse(response)

    process_response(response)
  end
end
