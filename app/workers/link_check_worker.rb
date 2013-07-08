class LinkCheckWorker
  include Sidekiq::Worker

  def perform(link_check_job_id)
    link_check_job = LinkCheckJob.find(link_check_job_id) rescue nil
    
    begin
      if link_check_job.present?
        sleep(2.seconds)
        RestClient.get(link_check_job.url)
      end
    rescue RestClient::ResourceNotFound => e
      RestClient.put("#{ENV['API_HOST']}/link_checker/records/#{link_check_job.record_id}", {record: {status: 'supressed'}})
    rescue Exception => e
      Rails.logger.warn("There was a unexpected error when trying to POST to #{ENV['API_HOST']}/link_checker/records/#{link_check_job.record_id} to update status to supressed")
      Rails.logger.warn("Exception: #{e.inspect}")
    end
  end
end