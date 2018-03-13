# frozen_string_literal: true

# app/models/network_checker.rb
class NetworkChecker
  def self.check
    RestClient.get('http://google.com')
    ENV['LINK_CHECKING_ENABLED'] = 'true'
  rescue StandardError
    ENV['LINK_CHECKING_ENABLED'] = nil
  end
end
