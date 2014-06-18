# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  module Enrichable
    extend ActiveSupport::Concern

    included do 
      include Mongoid::Document

      store_in session: 'api'

      embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiRecord::RecordFragment'
      delegate :title, :shelf_location, :relation, to: :primary
    end

    def primary
      self.fragments.where(priority: 0).first
    end

    def parent_tap_id
      extract_tap_id(:is_part_of) || extract_tap_id(:relation)
    end

    def tap_id
      extract_tap_id(:dc_identifier)
    end

    def authority_taps(name)
      primary.authorities.map {|authority| authority.authority_id if authority.name == name.to_s }.compact
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
      self.fragments.sort_by {|s| s.priority || Integer::INT32_MAX }
    end

    def extract_tap_id(field)
      tap_id = Array(primary[field]).find {|id| id.match(/tap:/) }
      tap_number = tap_id.to_s.match(/\d+/)
      tap_number ? tap_number[0].to_i : nil
    end
  end
end