module ValidatesResource
  extend ActiveSupport::Concern

  def collection_rule(source_id)
    @collection_rule ||= CollectionRules.find_by(source_id: source_id)
  end

  def validate_collection_rules(response, source_id)
    valid_status_code = valid_xpath = false
    rule = collection_rule(source_id)

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