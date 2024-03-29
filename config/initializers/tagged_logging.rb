# frozen_string_literal: true

return if Rails.env.test? || Rails.env.development?

module ActiveSupport
  module TaggedLogging
    module Formatter
      def call(severity, time, progname, data)
        data = { msg: data.to_s } unless data.is_a?(Hash)
        tags = current_tags
        data[:tags] = tags if tags.present?
        super(severity, time, progname, data)
      end
    end
  end
end
