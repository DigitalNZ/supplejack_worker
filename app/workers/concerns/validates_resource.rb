module ValidatesResource
  extend ActiveSupport::Concern

  def link_check_rule(source_id)
    @link_check_rule ||= LinkCheckRule.find_by(source_id: source_id) rescue nil
  end

  def validate_link_check_rule(response, source_id)
    valid_status_code = valid_xpath = false
    rule = link_check_rule(source_id)

    if rule.present?
      valid_status_code = validate_response_codes(response.code, rule.status_codes)
      valid_xpath = validate_xpath(rule.xpath, response.body)
    end

    valid_status_code and valid_xpath
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