# frozen_string_literal: true
module SupplejackApi
  module Enrichable
    extend ActiveSupport::Concern

    def primary
      fragments.select { |a| a.priority == 0 }.first
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
