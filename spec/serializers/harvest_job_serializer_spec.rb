# frozen_string_literal: true

require 'rails_helper'

describe HarvestJobSerializer do
  let!(:harvest_job) { create(:harvest_job) }
  let(:serialized) { described_class.new(harvest_job) }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get(
        "/parsers/#{harvest_job.parser_id}/versions/#{harvest_job.version_id}.json",
        { 'Accept' => 'application/json', 'Authorization' => "Token token=#{ENV['WORKER_KEY']}" },
        { parser: { source_id: 'response_source_id' } }.to_json,
        201
      )

      mock.get(
        "/parsers/#{harvest_job.parser_id}.json",
        { 'Accept' => 'application/json', 'Authorization' => "Token token=#{ENV['WORKER_KEY']}" },
        { parser: { source: { source_id: 'response_source_id' } } }.to_json,
        201
      )
    end
  end

  it 'renders the source_id attribute from the parser' do
    expect(serialized.serializable_hash[:source_id]).to eq 'response_source_id'
  end

  it 'renders _type attribute with proper value' do
    expect(serialized.serializable_hash[:_type]).to eq harvest_job._type
  end
end
