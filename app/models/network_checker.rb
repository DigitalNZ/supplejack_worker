class NetworkChecker

  def self.check
    begin
      response = RestClient.get("http://google.com")
      ENV["LINK_CHECKING_ENABLED"] = "true"
    rescue
      ENV["LINK_CHECKING_ENABLED"] = nil
    end
  end
end