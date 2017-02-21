# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class ApiDeleteWorker
	include Sidekiq::Worker
  sidekiq_options queue: 'default'

	def perform(identifier, job_id)
		job = AbstractJob.find(job_id)
		RestClient.put("#{ENV["API_HOST"]}/harvester/records/delete", {id: identifier}, {content_type: :json, accept: :json})
		job.inc(:posted_records_count => 1)
	end
end
