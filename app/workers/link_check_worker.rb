class LinkCheckWorker
  include Sidekiq::Worker

  def perform(link_check_job_id)
    link_check_job = LinkCheckJob.find(link_check_job_id) rescue nil
 
    begin
      if link_check_job.present?
        sleep(2.seconds)
        response = RestClient.get(link_check_job.url)
        supress_record(link_check_job.record_id) unless validate_collection_rules(response, link_check_job.primary_collection) 
      end
    rescue RestClient::ResourceNotFound => e
      supress_record(link_check_job.record_id)
    rescue Exception => e
      Rails.logger.warn("There was a unexpected error when trying to POST to #{ENV['API_HOST']}/link_checker/records/#{link_check_job.record_id} to update status to supressed")
      Rails.logger.warn("Exception: #{e.inspect}")
    end
  end

  def supress_record(record_id)
    RestClient.put("#{ENV['API_HOST']}/link_checker/records/#{record_id}", {record: {status: 'supressed'}})
  end

  def validate_collection_rules(response, collection)
    collection_rule = CollectionRules.find(:all, params: { collection_rules: { collection_title: collection} }).first
    status_code_matches = xpath_matches = false

    if collection_rule.present?
      status_code_matches = validate_response_codes(response.code, collection_rule.status_codes)
      xpath_matches = validate_xpath(collection_rule.xpath, response.body)
    end

    !status_code_matches and !xpath_matches
  end

  def validate_response_codes(response_code, response_code_blacklist)
    if response_code_blacklist.present?
      response_code_blacklist.split(",").each do |code|
        match = response_code.to_s.match(code.strip)

        return false if match.present?
      end
    end
    true
  end

  def validate_xpath(xpath, response_body)
    return true if xpath.blank?
    doc = Nokogiri::HTML.parse(response_body)
    doc.xpath(xpath).empty?
  end
end