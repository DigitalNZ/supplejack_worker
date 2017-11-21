# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe SupplejackApi::Enrichable do
  let(:record) { SupplejackApi::Record.new }
  let!(:primary_fragment) { record.fragments.build(dc_identifier: ['tap:1234'], priority: 0, is_part_of: ['tap:12345'], relation: ['tap:123456'], authorities: []) }
  let(:fragment) { record.fragments.build(dc_identifier: ['tap:1234'], priority: 1) }

  describe '#primary' do
    it 'returns the primary fragment' do
      record.primary.should eq primary_fragment
    end
  end

  describe '#tap_id' do
    it 'should extract the tap_id from the dc_identifier' do
      record.tap_id.should eq 1234
    end

    it 'should find the tap_id within multiple dc_identifiers' do
      primary_fragment.dc_identifier = ['other_id', 'tap:1234']
      record.tap_id.should eq 1234
    end
  end

  describe '#parent_tap_id' do
    it 'should extract the tap_id from the is_part_of' do
      record.parent_tap_id.should eq 12_345
    end

    it 'should return relation if there is no is_part_of' do
      primary_fragment.is_part_of = nil
      record.parent_tap_id.should eq 123_456
    end

    it 'should return nil if there is no is_part_of or relation' do
      primary_fragment.is_part_of = nil
      primary_fragment.relation = nil
      record.parent_tap_id.should eq nil
    end
  end

  describe '#authority_taps' do
    it 'should return the tap_id\'s of given authority_type' do
      primary_fragment.authorities.build(authority_id: 1, name: 'name_authority', text: 'name')
      primary_fragment.authorities.build(authority_id: 2, name: 'place_authority', text: 'place')

      record.authority_taps(:name_authority).should eq [1]
    end

    it 'should return [] if there are no matching authorities' do
      primary_fragment.authorities = nil
      record.authority_taps(:name_authority).should eq []
    end
  end

  describe '#authorities' do
    let(:fragment2) { record.fragments.build(priority: -1) }

    before(:each) do
      @auth1 = primary_fragment.authorities.build(authority_id: 1, name: 'name_authority', text: '')
      @auth2 = primary_fragment.authorities.build(authority_id: 2, name: 'name_authority', text: '')
      @auth3 = fragment2.authorities.build(authority_id: 2, name: 'name_authority', text: 'John Doe')
    end

    it 'merges authorities based on priority' do
      record.authorities.count.should eq 2
      record.authorities.should include(@auth1)
      record.authorities.should include(@auth3)
    end
  end

  describe '#locations' do
    let(:fragment_2) { record.fragments.build }

    before(:each) do
      @loc1 = primary_fragment.locations.build(placename: 'Wellington')
      @loc2 = primary_fragment.locations.build(placename: 'China')
      @loc3 = fragment_2.locations.build(placename: 'Japan')
    end

    it 'returns all the locations from all the fragments' do
      record.locations.should include(@loc1, @loc2, @loc3)
    end
  end

  describe '#sorted_fragments' do
    it 'returns a list of fragments sorted by priority' do
      record.fragments.build(priority: 10)
      record.fragments.build(priority: -1)
      record.fragments.build(priority: 5)

      record.send(:sorted_fragments).map(&:priority).should eq [-1, 0, 5, 10]
    end
  end
end
