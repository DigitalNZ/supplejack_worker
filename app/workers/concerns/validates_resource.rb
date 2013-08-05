module ValidatesResource
  extend ActiveSupport::Concern

  def collection_rule(primary_collection)
    @collection_rule ||= CollectionRules.find(:all, params: { collection_rules: { collection_title: primary_collection} }).first
  end

  def validate_collection_rules(response, primary_collection)
    valid_status_code = valid_xpath = false
    rule = collection_rule(primary_collection)

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