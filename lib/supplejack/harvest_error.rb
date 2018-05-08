# frozen_string_literal: true

module Supplejack
  # lib/supplejack/exceptions.rb
  class HarvestError < StandardError
    attr_reader :message, :backtrace, :raw_data, :parser_id

    def initialize(message, backtrace, raw_data, parser_id = nil)
      @message = message
      @backtrace = backtrace
      @raw_data = raw_data
      @parser_id = parser_id
    end
  end
end
