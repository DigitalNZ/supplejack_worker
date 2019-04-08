# frozen_string_literal: true
require 'rails_helper'

describe ApiUpdateWorker do
  let(:worker) { ApiUpdateWorker.new }
  let(:job) { create(:harvest_job) }
  let(:parser) { Parser.new(strategy: 'xml', name: 'Natlib Pages', content: 'class NatlibPages < SupplejackCommon::Xml::Base; end', file_name: 'natlib_pages.rb', source: { source_id: 'source_id' }, id: 1) }

  before(:each) do
    allow_any_instance_of(HarvestJob).to receive(:parser) { parser }
  end

  it 'is retryable' do
    expect(described_class).to be_retryable 5
  end

  describe '#perform' do
    let(:success_response) do
      {
        status: 'success',
        record_id: 123
      }
    end

    let(:failed_response) do
      {
        status: 'failed',
        exception_class: 'Exception',
        message: 'Error message',
        raw_data: 'some data',
        record_id: 123
      }
    end

    before(:each) do
      allow(AbstractJob).to receive(:find).and_return(job)
    end

    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'post attributes to the api' do
      expect(RestClient).to receive(:post).and_return(success_response.to_json)
      worker.perform('/harvester/records/123/fragments.json', {}, 1)
    end

    it 'merges preview=true into attributes if environment is preview' do
      allow(job).to receive(:environment) { 'preview' }

      expect(RestClient).to receive(:post) { |_, attributes, _|
        expect(attributes).to eq({ preview: true, api_key: ENV['HARVESTER_API_KEY'] }.to_json)
      }.and_return(success_response.to_json)

      worker.perform('/harvester/records/123/fragments.json', {}, 1)
    end

    context 'Api return status: :failed' do
      before(:each) do
        allow(RestClient).to receive(:post).and_return(failed_response.to_json)
      end

      it 'raises Supplejack::HarvestError exception' do
        expect { worker.perform('/harvester/records/123/fragments.json', {}, 1) }.to raise_error(Supplejack::HarvestError)
      end
    end

    context 'API return a status: :success' do
      before(:each) do
        allow(RestClient).to receive(:post).and_return(success_response.to_json)
      end

      it 'increments job.posted_records_count' do
        expect(job).to receive(:inc).with(posted_records_count: 1)
        worker.perform('/harvester/records/123/fragments.json', {}, 1)
      end

      it 'updates job.last_posted_record_id and job.updated_at' do
        expect(job).to receive(:set).with(updated_at: Time.zone.now.change(usec: 0), last_posted_record_id: 123)

        worker.perform('/harvester/records/123/fragments.json', {}, 1)
      end
    end
  end
end
