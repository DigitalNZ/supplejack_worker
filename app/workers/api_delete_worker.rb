class ApiDeleteWorker
	include Sidekiq::Worker

	def perform(identifier, job_id)
		job = AbstractJob.find(job_id)
		RestClient.put("#{ENV["API_HOST"]}/harvester/records/delete", {id: identifier}, {content_type: :json, accept: :json})
		job.inc(:posted_records_count, 1)
	end
end