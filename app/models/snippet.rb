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
