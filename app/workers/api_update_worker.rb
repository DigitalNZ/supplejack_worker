# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack
class ApiUpdateWorker < AbstractWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 5, backtrace: true
  sidekiq_retry_in { 5.seconds }

  sidekiq_retries_exhausted do |msg, e|
    Airbrake.notify(msg)

    job_id = msg['args'].last
    job = AbstractJob.find(job_id)

    job.failed_records << FailedRecord.new(
      exception_class: msg['class'],
      message: e.message,
      backtrace: e.backtrace,
      raw_data: e.raw_data.to_json
    )

    job.inc(posted_records_count: 1)
  end

  def perform(path, attributes, job_id)
    @job_id = job_id
    return if stop_harvest?

    attributes[:preview] = true if job.environment == 'preview'

    response = RestClient.post(
      "#{ENV['API_HOST']}#{path}",
      attributes.merge(api_key: ENV['HARVESTER_API_KEY']).to_json,
      content_type: :json, accept: :json
    )
    response = JSON.parse(response)

    process_response(response)
  end
end
