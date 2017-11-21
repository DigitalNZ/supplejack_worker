# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe ApiDeleteWorker do
  let(:worker) { ApiDeleteWorker.new }
  let(:job) { FactoryBot.create(:harvest_job) }

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

    it 'put attributes to the api' do
      RestClient.should_receive(:put).and_return(success_response.to_json)
      worker.perform('/harvester/records/123/fragments.json', {})
    end

    context 'API return a status: :failed' do
      before(:each) do
        RestClient.stub(:put).and_return(failed_response.to_json)
      end

      it 'triggers an Airbrake notification' do
        described_class.within_sidekiq_retries_exhausted_block {
          expect(Airbrake).to receive(:notify)
        }
      end

      it 'creates a new instance of FailedRecord' do
        described_class.within_sidekiq_retries_exhausted_block {
          expect(FailedRecord).to receive(:new).with(exception_class: 'ApiDeleteWorker', message: 'An error occured', backtrace: nil, raw_data: '[]')
        }
      end

      it 'raises an exception' do
        expect { worker.perform('/harvester/records/123/fragments.json', {}) }.to raise_exception
      end
    end

    context 'API return a status: :success' do
      before(:each) do
        RestClient.stub(:put).and_return(success_response.to_json)
      end

      it 'increments job.posted_records_count' do
        job.should_receive(:inc).with(posted_records_count: 1)

        worker.perform('/harvester/records/123/fragments.json', {})
      end

      it 'updates job.last_posted_record_id' do
        job.should_receive(:set).with(last_posted_record_id: 123)

        worker.perform('/harvester/records/123/fragments.json', {})
      end
    end
  end
end
