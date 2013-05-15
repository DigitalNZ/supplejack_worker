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