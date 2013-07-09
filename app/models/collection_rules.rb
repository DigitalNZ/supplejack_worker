class CollectionRules < ActiveResource::Base

  self.site = ENV['MANAGER_HOST']
  self.user = ENV['MANAGER_API_KEY']

end