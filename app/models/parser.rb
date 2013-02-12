class Parser < ActiveResource::Base

  self.site = ENV['MANAGER_HOST'] + "/parsers/:parser_id/"
  self.user = ENV['MANAGER_API_KEY']
  self.element_name = "version"

  def loader
    @loader ||= ParserLoader.new(self)
  end

  def load_file
    loader.load_parser
  end
end