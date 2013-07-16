class ApiDeleteWorker
	include Sidekiq::Worker

	def perform(identifier, job_id)
		job = AbstractJob.find(job_id)
		RestClient.delete("#{ENV["API_HOST"]}/harvester/records/#{identifier}", content_type: :json, accept: :json)
		job.inc(:posted_records_count, 1)
	end
end