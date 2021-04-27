# frozen_string_literal: true

module ActiveSupport
  module TaggedLogging
    module Formatter
      def call(severity, time, progname, data)
        data = { msg: data.to_s } unless data.is_a?(Hash)
        tags = current_tags
        data[:tags] = tags if tags.present?
        _call(severity, time, progname, data)
      end
    end
  end
end

class CustomLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include ActiveSupport::LoggerSilence

  def create_formatter
    Ougai::Formatters::Bunyan.new
  end
end
