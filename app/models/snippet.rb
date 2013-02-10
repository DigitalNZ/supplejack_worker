class Snippet < ActiveResource::Base
  
  self.site = ENV['MANAGER_HOST']
  self.user = ENV['MANAGER_API_KEY']

  def self.find_by_name(name)
    find(:one, from: :search, params: {name: name})
  end

end