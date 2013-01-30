class Parser < ActiveResource::Base

  self.site = ENV['MANAGER_HOST']
  
  def file_name
    @file_name ||= self.name.downcase.gsub(/\s/, "_") + ".rb"
  end

  def loader
    @loader ||= ParserLoader.new(self)
  end

  def load_file
    loader.load_parser
  end
end