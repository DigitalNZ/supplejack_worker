# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module ParserLoaderHelpers
  attr_reader :loader

  def load_file(environment)
    @loader ||= SupplejackCommon::Loader.new(self, environment)
    loader.load_parser
  end

  def enrichment_definitions(environment)
    return @enrichment_definitions if @enrichment_definitions
    @loader ||= SupplejackCommon::Loader.new(self, environment)

    if loader.loaded?
      @enrichment_definitions = loader.parser_class.enrichment_definitions
    end
  end
end
