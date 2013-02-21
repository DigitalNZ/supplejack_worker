class Parser < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST']
  self.user = ENV['MANAGER_API_KEY']

end