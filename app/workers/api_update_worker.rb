# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class ApiUpdateWorker < AbstractWorker
	include Sidekiq::Worker

	def perform(path, attributes, job_id)
    @job = AbstractJob.find(job_id)
    return if self.stop_harvest?

		attributes.merge!(preview: true) if @job.environment == "preview"

		measure = Benchmark.measure do
      tries = 0
      begin
        if tries < 10
          response = RestClient::Request.execute(method: :post, url: "#{ENV["API_HOST"]}#{path}", payload: attributes.to_json, timeout: 10, open_timeout: 10, headers: {content_type: :json, accept: :json})
          response = JSON.parse(response)
          @job.set(last_posted_record_id: response["record_id"])
        end
      rescue RestClient::RequestTimeout => e
        Sidekiq.logger.info "ApiUpdateWorker POST to API failed, tries: #{tries}"
        tries += 1
        retry
      end
    end

    @job.inc(:posted_records_count => 1)

    Sidekiq.logger.info "POST #{@job.class} #{@job.environment.capitalize} to #{path}. Time: #{measure.real.round(4)}s"
	end
end
