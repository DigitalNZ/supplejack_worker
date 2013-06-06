module ParserLoaderHelpers
  def loader
    @loader ||= HarvesterCore::Loader.new(self)
  end

  def load_file
    loader.load_parser
  end

  def enrichment_definitions
    return @enrichment_definitions if @enrichment_definitions

    if loader.loaded?
      @enrichment_definitions = loader.parser_class.enrichment_definitions.freeze
    end
  end
end