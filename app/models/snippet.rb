# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class Snippet < ActiveResource::Base

  self.site = ENV['MANAGER_HOST']
  self.user = ENV['MANAGER_API_KEY']

  def self.find_by_name(name, environment)
    begin
      snippet = find(:one, from: :current_version, params: {name: name, environment: environment})
    rescue StandardError => e
      Rails.logger.error "Snippet with name: #{name} was not found"
      Airbrake.notify(e)
      return nil
    end
  end

end
