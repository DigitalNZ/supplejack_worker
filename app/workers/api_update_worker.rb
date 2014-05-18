# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class ApiUpdateWorker
	include Sidekiq::Worker

	def perform(path, attributes, job_id)
		job = AbstractJob.find(job_id)

		attributes.merge!(preview: true) if job.environment == "preview"

		measure = Benchmark.measure do
      response = RestClient.post "#{ENV["API_HOST"]}#{path}", attributes.to_json, content_type: :json, accept: :json
      response = JSON.parse(response)
      job.set(:last_posted_record_id, response["record_id"])
    end

    job.inc(:posted_records_count, 1)

    puts "#{job.class}: POST (#{measure.real.round(4)})" unless Rails.env.test?
	end
end