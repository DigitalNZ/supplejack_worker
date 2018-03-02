# frozen_string_literal: true
require 'rails_helper'

describe SupplejackApi::Enrichable do
  let(:records) { SupplejackApi::Record.find('fragments.source_id' => 'digitalnz-sets') }

  before do
    records_response = [{
      id: '5a81fa176a694240d94c9592',
      fragments: [
        { priority: 1, locations: %w[a b] },
        { priority: 0, locations: %w[c d] }
      ]
    }].to_json

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/harvester/records.json?api_key=AS4wGKGRVgEszC_iyEUc&search%5Bfragments.source_id%5D=digitalnz-sets', {'Accept'=>'application/json'}, records_response, 201
    end
  end

  describe '#primary' do
    it 'returns the primary fragment' do
      expect(records.first.primary.priority).to be 0
    end
  end

  describe '#locations' do
    it 'returns all the locations from all the fragments' do
      expect(records.first.locations).to eq %w[a b c d]
    end
  end

  describe '#sorted_fragments' do
    it 'returns a list of fragments sorted by priority' do
      expect(records.first.send(:sorted_fragments).map(&:priority)).to eq [0, 1]
    end
  end

  describe '#find' do
    it 'should pass the api_key as a parameter' do
      expect(ActiveResource::Base).to receive(:find).with(:all, params: { search: { 'fragments.source_id' => 'digitalnz-sets' }, api_key: ENV['HARVESTER_API_KEY'] })
      SupplejackApi::Record.find('fragments.source_id' => 'digitalnz-sets')
    end
  end
end
