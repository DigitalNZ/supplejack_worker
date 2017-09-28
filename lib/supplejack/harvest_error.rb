# frozen_string_literal: true

module Supplejack
  # lib/supplejack/exceptions.rb
  class HarvestError < StandardError
    attr_reader :message, :backtrace, :raw_data

    def initialize(message, backtrace, raw_data)
      @message = message
      @backtrace = backtrace
      @raw_data = raw_data
    end
  end
end
