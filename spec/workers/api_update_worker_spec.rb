# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe ApiUpdateWorker do
  let(:worker) { ApiUpdateWorker.new }
  let(:job) { create(:harvest_job) }

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
      AbstractJob.stub(:find).and_return(job)
    end

    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'post attributes to the api' do
      RestClient.should_receive(:post).and_return(success_response.to_json)
      worker.perform('/harvester/records/123/fragments.json', {}, 1)
    end

    it 'merges preview=true into attributes if environment is preview' do
      job.stub(:environment) { 'preview' }

      RestClient.should_receive(:post) do |_, attributes, _|
        expect(attributes).to eq({ preview: true, api_key: ENV['HARVESTER_API_KEY'] }.to_json)
      end.and_return(success_response.to_json)

      worker.perform('/harvester/records/123/fragments.json', {}, 1)
    end

    context 'Api return status: :failed' do
      before(:each) do
        RestClient.stub(:post).and_return(failed_response.to_json)
      end

      it 'raises Supplejack::HarvestError exception' do
        expect { worker.perform('/harvester/records/123/fragments.json', {}, 1) }.to raise_error(Supplejack::HarvestError)
      end
    end

    context 'API return a status: :success' do
      before(:each) do
        RestClient.stub(:post).and_return(success_response.to_json)
      end

      it 'increments job.posted_records_count' do
        job.should_receive(:inc).with(posted_records_count: 1)

        worker.perform('/harvester/records/123/fragments.json', {}, 1)
      end

      it 'updates job.last_posted_record_id' do
        job.should_receive(:set).with(last_posted_record_id: 123)

        worker.perform('/harvester/records/123/fragments.json', {}, 1)
      end
    end
  end
end
