class ApiUpdateWorker
	include Sidekiq::Worker

	def perform(record_id, attributes, enrichment_job_id)
		measure = Benchmark.measure do
      RestClient.post "#{ENV["API_HOST"]}/harvester/records/#{record_id}/sources.json", {source: attributes}.to_json, :content_type => :json, :accept => :json
    end

    job = EnrichmentJob.find(enrichment_job_id)
    job.inc(:posted_records_count,1)

    puts "EnrichmentJob: POST (#{measure.real.round(4)})" unless Rails.env.test?
	end
end