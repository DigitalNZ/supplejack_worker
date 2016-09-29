# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module ParserLoaderHelpers
  attr_reader :loader

  # Return a parser based on the latest version within specific environment
  # @param environment of the parser that needs to be loaded
  # @author Jeffery Liang
  def load_file(environment)
    SupplejackCommon::Oai::Base.clear_definitions
    # The SupplejackCommon::Oai::Base include a cache-alike mechanism to store options' container with (identifiter => set) 
    # invoking clear_definition will clear such attributes "set" in the base class
    @loader ||= SupplejackCommon::Loader.new(self, environment)
    loader.load_parser
  end

  # Return a definition based on the latest parser version within specific environment
  # @param environment of the parser whose enrichment is requested
  # @author Jeffery Liang
  def enrichment_definitions(environment)
    return @enrichment_definitions if @enrichment_definitions
    # the same reason that we use clear_definition in the load_file method
    SupplejackCommon::Oai::Base.clear_definitions
    @loader ||= SupplejackCommon::Loader.new(self, environment)
    if loader.loaded?
      @enrichment_definitions = loader.parser_class.enrichment_definitions
    end
  end
end
