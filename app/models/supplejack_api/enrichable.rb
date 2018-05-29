# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/enrichable.rb
  module Enrichable
    extend ActiveSupport::Concern

    def primary
      fragments.select { |a| a.priority.zero? }.first
    end

    def locations
      fragments.map(&:locations).flatten
    end

    private

    def sorted_fragments
      fragments.sort_by { |s| s.priority || Integer::INT32_MAX }
    end
  end
end
