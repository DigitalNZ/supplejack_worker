class LinkCheckWorker
  include Sidekiq::Worker

  sidekiq_options :retry => 100

  sidekiq_retry_in { |count| 2 * Random.rand(1..5) }

  def perform(link_check_job_id, strike=0)
    @link_check_job_id = link_check_job_id
    begin
      if link_check_job.present?
        response = link_check(link_check_job.url, link_check_job.primary_collection)
        if validate_collection_rules(response, link_check_job.primary_collection)
          set_record_status(link_check_job.record_id, "active") if strike > 0
        else
          suppress_record(link_check_job_id, link_check_job.record_id, strike)
        end
      end
    rescue RestClient::ResourceNotFound => e
      suppress_record(link_check_job_id, link_check_job.record_id, strike)
    rescue Exception => e
      Rails.logger.warn("There was a unexpected error when trying to POST to #{ENV['API_HOST']}/link_checker/records/#{link_check_job.record_id} to update status to supressed")
      Rails.logger.warn("Exception: #{e.inspect}")
    end
  end

  private

  def add_record_stats(record_id, status)
    status = "activated" if status == "active"
    collection_stats.add_record!(record_id, status, link_check_job.url)
  end

  def collection_stats
    @collection_stats ||= CollectionStatistics.where(collection_title: link_check_job.primary_collection).find_or_create_by(day: Date.today)
  end

  def link_check_job
    @link_check_job ||= LinkCheckJob.find(@link_check_job_id) rescue nil
  end

  def link_check(url, collection)
    Sidekiq.redis do |conn| 
      if conn.setnx(collection, 0)
        conn.expire(collection, 2)
        RestClient.get(url)
      else
        raise Exception.new("Could not aquire redis lock")
      end
    end
  end

  def suppress_record(link_check_job_id, record_id, strike)
    timings = {0 => 1.hours, 1 => 5.hours, 2 => 72.hours}
    
    if strike >= 3
      set_record_status(record_id, "deleted")
    else
      set_record_status(record_id, "suppressed") unless strike > 0
      LinkCheckWorker.perform_in(timings[strike], link_check_job_id, strike + 1)
    end
  end

  def set_record_status(record_id, status)
    begin
      RestClient.put("#{ENV['API_HOST']}/link_checker/records/#{record_id}", {record: {status: status}})
      add_record_stats(record_id, status)
    rescue Exception => e
      Rails.logger.warn("Record not found. Ignoring.")
    end
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