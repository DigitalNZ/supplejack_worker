class ApiDeleteWorker
	include Sidekiq::Worker

	def perform(identifier)
		RestClient.delete("#{ENV["API_HOST"]}/harvester/records/#{identifier}", content_type: :json, accept: :json)
	end
end