module ParserLoaderHelpers
  def loader
    @loader ||= ParserLoader.new(self)
  end

  def load_file
    loader.load_parser
  end
end