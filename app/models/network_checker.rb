# frozen_string_literal: true
class NetworkChecker
  def self.check
    response = RestClient.get('http://google.com')
    ENV['LINK_CHECKING_ENABLED'] = 'true'
  rescue
    ENV['LINK_CHECKING_ENABLED'] = nil
  end
end
