# frozen_string_literal: true

module SupplejackApi
  # :nodoc:
  module Enrichable
    extend ActiveSupport::Concern

    # included do
    #   include Mongoid::Document
    #   include Mongoid::Attributes::Dynamic

    #   store_in client: 'api'

    #   embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiRecord::RecordFragment'
    #   delegate :title, :shelf_location, :relation, to: :primary
    # end

    def primary
      fragments.where(priority: 0).first
    end

    def parent_tap_id
      extract_tap_id(:is_part_of) || extract_tap_id(:relation)
    end

    def tap_id
      extract_tap_id(:dc_identifier)
    end

    def authority_taps(name)
      primary.authorities.map do |authority|
        authority.authority_id if authority.name == name.to_s
      end.compact
    end

    def authorities
      authorities = {}
      sorted_fragments.each do |fragment|
        fragment.authorities.each do |authority|
          authorities["#{authority.authority_id}-#{authority.name}"] ||= authority
        end
      end
      authorities.values
    end

    def locations
      fragments.map(&:locations).flatten
    end

    private

    def sorted_fragments
      fragments.sort_by { |s| s.priority || Integer::INT32_MAX }
    end

    def extract_tap_id(field)
      tap_id = Array(primary[field]).find { |id| id.match(/tap:/) }
      tap_number = tap_id.to_s.match(/\d+/)
      tap_number ? tap_number[0].to_i : nil
    end
  end
end
