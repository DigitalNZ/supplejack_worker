# frozen_string_literal: true
require 'rails_helper'

describe ApiDeleteWorker do
  let(:worker) { ApiDeleteWorker.new }
  let(:job) { create(:harvest_job) }

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

    it 'put attributes to the api' do
      expect(RestClient).to receive(:put).and_return(success_response.to_json)
      worker.perform('/harvester/records/123/fragments.json', {})
    end

    context 'API return a status: :failed' do
      before(:each) do
        allow(RestClient).to receive(:put).and_return(failed_response.to_json)
      end

      it 'triggers an Airbrake notification' do
        described_class.within_sidekiq_retries_exhausted_block do
          expect(Airbrake).to receive(:notify)
        end
      end

      it 'creates a new instance of FailedRecord' do
        described_class.within_sidekiq_retries_exhausted_block do
          expect(FailedRecord).to receive(:new).with(exception_class: 'ApiDeleteWorker', message: 'An error occured', backtrace: nil, raw_data: '[]')
        end
      end

      it 'raises an invalid request Active Resource exception' do
        expect { worker.perform('/harvester/records/123/fragments.json', {}) }.to raise_exception(ActiveResource::InvalidRequestError)
      end
    end

    context 'API return a status: :success' do
      before(:each) do
        allow(RestClient).to receive(:put).and_return(success_response.to_json)
      end

      it 'increments job.posted_records_count' do
        expect(job).to receive(:inc).with(posted_records_count: 1)

        worker.perform('/harvester/records/123/fragments.json', {})
      end

      it 'updates job.last_posted_record_id and job.updated_at' do
        expect(job).to receive(:set).with(updated_at: Time.zone.now.change(:usec => 0), last_posted_record_id: 123)

        worker.perform('/harvester/records/123/fragments.json', {})
      end
    end
  end
end
