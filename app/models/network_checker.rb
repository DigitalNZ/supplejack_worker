# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

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