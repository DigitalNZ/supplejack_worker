module ParserLoaderHelpers
  def loader
    @loader ||= HarvesterCore::Loader.new(self)
  end

  def load_file
    loader.load_parser
  end

  def enrichment_definitions
    if loader.loaded?
      loader.parser_class.enrichment_definitions
    end
  end
end