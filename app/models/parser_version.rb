class ParserVersion < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST'] + "/parsers/:parser_id/"
  self.user = ENV['MANAGER_API_KEY']
  self.element_name = "version"

end