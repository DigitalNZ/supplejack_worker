# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

describe ApiDeleteWorker do
  let(:worker) { ApiDeleteWorker.new }
  let(:job) { FactoryGirl.create(:harvest_job) }

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

      it 'increments job.posted_records_count' do
        job.should_receive(:inc).with(posted_records_count: 1)
        worker.perform('/harvester/records/123/fragments.json', {})
      end

      it 'updates job.last_posted_record_id' do
        job.should_receive(:set).with(last_posted_record_id: 123)
        worker.perform('/harvester/records/123/fragments.json', {})
      end

      it 'adds a FailedRecord to job.failed_records array' do
        exception_class = failed_response[:exception_class]
        message = failed_response[:message]
        raw_data = failed_response[:raw_data]

        worker.perform('/harvester/records/123/fragments.json', {})
        failed = job.failed_records.first

        expect(failed.attributes['exception_class']).to eq exception_class
        expect(failed.attributes['message']).to eq message
        expect(failed.attributes['raw_data']).to eq raw_data
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