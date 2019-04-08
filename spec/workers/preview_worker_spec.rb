# frozen_string_literal: true
require 'rails_helper'

describe PreviewWorker do
  let(:parser) { Parser.new(strategy: 'xml', name: 'Natlib Pages', content: 'class NatlibPages < SupplejackCommon::Xml::Base; end', file_name: 'natlib_pages.rb', source: { source_id: 'source_id' }) }
  let(:job) { HarvestJob.new(environment: 'preview', parser_id: 'abc123', index: 3, harvest_failure: {}, last_posted_record_id: 1234, updated_at: Time.zone.now) }
  let(:preview) { mock_model(Preview, _id: '123').as_null_object }

  let(:worker) { PreviewWorker.new }

  let(:record1) { double(:record, raw_data: '{"id": "123"}', attributes: { title: 'Clip the dog', data_type: 'record' }, field_errors: {}, validation_errors: {}) }
  let(:record2) { double(:record) }

  before do
    allow(worker).to receive(:job) { job }
    allow(job).to receive(:records).and_yield(record1, 0).and_yield(record2, 1).and_yield(record1, 2).and_yield(record2, 3)
    allow(record1).to receive(:valid?) { true }
    allow(record2).to receive(:valid?) { true }
    allow(worker).to receive(:preview) { preview }
    allow(preview).to receive(:update_attribute)
    allow(worker).to receive(:current_record_id) { 1234 }
  end

  describe '#perform' do
    before do
      allow(worker).to receive(:preview) { preview }
      allow(worker).to receive(:process_record)
      allow(worker).to receive(:enrich_record)
      allow(job).to receive(:finish!)
      allow(worker).to receive(:stop_harvest?) { false }
    end

    it 'is a critical job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'critical'
    end

    it 'sets @job_id to the harvest_job_id' do
      worker.perform('abc123', 'preview123')
      expect(worker.job_id).to eq 'abc123'
    end

    it 'sets @job_id' do
      worker.perform({ '$oid' => 'abc123' }, 'preview123')
      expect(worker.job_id).to eq 'abc123'
    end

    it 'iterates through each of the jobs records' do
      expect(job).to receive(:records).and_yield(record1, 0).and_yield(record1, 1)
      worker.perform('abc123', 'preview123')
    end

    it 'should only process 1 record that is at the given index' do
      expect(worker).to receive(:process_record).with(record2)
      worker.perform('abc123', 'preview123')
    end

    it 'should only process 1 record that is at the given index' do
      expect(worker).to receive(:process_record).once
      worker.perform('abc123', 'preview123')
    end

    it 'should enrich the record' do
      expect(worker).to receive(:enrich_record).once
      worker.perform('abc123', 'preview123')
    end

    it 'calls finish!' do
      expect(job).to receive(:finish!)
      worker.perform('abc123', 'preview123')
    end

    context 'harvest_failure' do
      before { allow(job).to receive(:harvest_failure) { '{"error":"message"}' } }

      it 'should update the preview object with validation errors' do
        expect(preview).to receive(:update_attribute).with(:harvest_failure, job.harvest_failure.to_json)
        worker.perform('abc123', 'preview123')
      end
    end

    context 'sidekiq_retries_exhausted' do
      before { allow(AbstractJob).to receive(:find).and_return(job) }
      before { allow(Preview).to receive(:find).and_return(preview) }
      before { allow(job).to receive(:parser) { parser } }

      it 'should update the end time' do
        worker.perform('abc123', 'preview123')

        described_class.within_sidekiq_retries_exhausted_block do
          expect(job).to receive(:update_attribute).twice
        end

        expect(job.end_time).to_not eq nil
        expect(job.end_time.day).to eq Time.zone.now.day
      end
    end

    context 'stopped jobs' do
      before { allow(worker).to receive(:stop_harvest?) { true } }

      it 'does not call preview_record if the job is stopped' do
        expect(worker).to_not receive(:process_record)
      end

      it 'does not call enrich_record if the job is stopped' do
        expect(worker).to_not receive(:enrich_record)
      end
    end
  end

  describe '#strip_ids' do
    it "strips the _id's from all documents in record" do
      result = worker.send(:strip_ids, '_id' => '123',
                                       'blah' => 'blah',
                                       'fragments' => {
                                         '_id' => '12',
                                         'authorities' => [{ '_id' => 'ab12' }, 'blah']
                                       })
      expect(result).to_not include('_id' => '123')
      expect(result['fragments']).to_not include('_id' => '12')
      expect(result['fragments']['authorities'][0]).to_not include('_id' => 'ab12')
      expect(result).to include('blah' => 'blah')
    end

    it 'returns nil if nil is passed' do
      expect(worker.send(:strip_ids, nil)).to eq nil
    end
  end

  describe '#preview' do
    before do
      allow(worker).to receive(:preview).and_call_original
      worker.instance_variable_set(:@preview_id, '123')
    end

    it 'should find the preview object' do
      expect(Preview).to receive(:find).with('123') { preview }
      worker.send(:preview)
    end

    it 'should memoize the find' do
      expect(Preview).to receive(:find).with('123').once { preview }
      worker.send(:preview)
      worker.send(:preview)
    end
  end

  describe '#process_record' do
    before do
      allow(worker).to receive(:preview) { preview }
      allow(record1).to receive(:deletable?) { false }
      allow(record1).to receive(:errors) { {} }
      allow(preview).to receive(:save)
      allow(job).to receive_message_chain(:parser, :source, :source_id) { 'tahpuhi' }
      allow(job).to receive_message_chain(:parser, :data_type) { 'record' }
    end

    it "should update the attribute status to: 'harvesting record'" do
      expect(preview).to receive(:update_attribute).with(:status, 'Parser loaded and data fetched. Parsing raw data and checking harvest validations...')
      worker.send(:process_record, record1)
    end

    it 'should update the preview object with the raw data' do
      expect(preview).to receive(:raw_data=).with(record1.raw_data)
      worker.send(:process_record, record1)
    end

    it 'should update the preview object with the harvested_attributes' do
      record1.attributes[:source_id] = 'tahpuhi'
      expect(preview).to receive(:harvested_attributes=).with(record1.attributes.to_json)
      worker.send(:process_record, record1)
    end

    it 'should update the preview object with whether it is deletable or not' do
      expect(preview).to receive(:deletable=).with(false)
      worker.send(:process_record, record1)
    end

    it 'should update the preview object with field errors' do
      expect(preview).to receive(:field_errors=).with(record1.field_errors.to_json)
      worker.send(:process_record, record1)
    end

    context 'validation errors' do
      before { allow(record1).to receive(:valid?) { false } }

      it 'should update the preview object with validation errors' do
        expect(preview).to receive(:validation_errors=).with([].to_json)
        worker.send(:process_record, record1)
      end
    end

    it 'should save the preview object' do
      expect(preview).to receive(:save!)
      worker.send(:process_record, record1)
    end
  end

  describe '#current_record_id' do
    before { allow(worker).to receive(:current_record_id).and_call_original }
    it 'should reload the job and return the last last_posted_record_id' do
      expect(job).to receive(:reload) { job }
      expect(worker.send(:current_record_id)).to eq '1234'
    end
  end

  describe '#enrich_record' do
    let(:record) { double(:record, attributes: { title: 'Hello' }) }

    before do
      ActiveResource::HttpMock.respond_to do |mock|
        url = "/harvester/preview_records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Brecord_id%5D=1234"
        mock.get url, {'Accept'=>'application/json'}, [record].to_json, 201
      end

      allow(record1).to receive(:valid?) { true }
      allow(record1).to receive(:deletable?) { false }
      allow(job).to receive_message_chain(:parser, :enrichment_definitions) { {} }
      allow(SupplejackApi::PreviewRecord).to receive(:where) { [record] }
      allow(worker).to receive(:strip_ids) { record.attributes }
      allow(worker).to receive(:post_to_api)
    end

    context 'record not valid' do
      before { allow(record1).to receive(:valid?) { false } }

      it 'should not post to API if the record is not valid' do
        expect(worker).to_not receive(:post_to_api)
        worker.send(:enrich_record, record1)
      end
    end

    context 'record is a deletion' do
      before do
        ActiveResource::HttpMock.respond_to do |mock|
          url = "/harvester/records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Bfragments.job_id%5D=#{job.id.to_s}"
          mock.get url, {'Accept'=>'application/json'}, [].to_json, 201
        end

        allow(record1).to receive(:deletable?) { true }
      end

      it 'should not post to API if the record is not valid' do
        expect(worker).to_not receive(:post_to_api)
        worker.send(:enrich_record, record1)
      end
    end

    it 'should post the record to the API' do
      expect(worker).to receive(:post_to_api).with(record1.attributes, false)
      worker.send(:enrich_record, record1)
    end

    context 'enrichments defined' do
      let(:enrichment_job) { EnrichmentJob.new }
      let(:enrichment_worker) { double(:enrichment_worker) }

      before do
        allow(job).to receive_message_chain(:parser, :enrichment_definitions).and_return(ndha: {})
        allow(EnrichmentJob).to receive(:create_from_harvest_job) { enrichment_job }
        allow_any_instance_of(EnrichmentWorker).to receive(:perform)
      end

      it 'should create a enrichment job' do
        expect(EnrichmentJob).to receive(:create_from_harvest_job).with(job, :ndha)
        worker.send(:enrich_record, record1)
      end

      it 'should update the enrichment jobs record_id using current_record_id' do
        worker.send(:enrich_record, record1)
        expect(enrichment_job.record_id).to eq 1234
      end

      it 'should enqueue a job for the EnrichmentWorker' do
        expect(EnrichmentWorker).to receive(:new) { enrichment_worker }
        expect(enrichment_worker).to receive(:perform).with(enrichment_job.id)
        worker.send(:enrich_record, record1)
      end
    end

    it 'should find the preview record' do
      expect(SupplejackApi::PreviewRecord).to receive(:find).with(record_id: 1234) { [record] }
      worker.send(:enrich_record, record1)
    end

    it 'should set the previews api_record' do
      expect(preview).to receive(:update_attribute).with(:api_record, record.attributes.to_json)
      worker.send(:enrich_record, record1)
    end
  end

  describe '#validation_errors' do
    let(:record) { double(:record) }

    it 'returns the validation errors' do
      allow(record).to receive(:errors) { { title: 'WRONG!' } }
      expect(worker.send(:validation_errors, record)).to eq([{ title: 'WRONG!' }])
    end

    it 'returns an empty hash if there is no @last_processed_record ' do
      allow(record).to receive(:errors) { {} }
      expect(worker.send(:validation_errors, record)).to be_empty
    end
  end
end
