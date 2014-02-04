module ParserLoaderHelpers
  attr_reader :loader

  def load_file(environment)
    @loader ||= HarvesterCore::Loader.new(self, environment)
    loader.load_parser
  end

  def enrichment_definitions(environment)
    return @enrichment_definitions if @enrichment_definitions
    @loader ||= HarvesterCore::Loader.new(self, environment)

    if loader.loaded?
      @enrichment_definitions = loader.parser_class.enrichment_definitions
    end
  end
end
