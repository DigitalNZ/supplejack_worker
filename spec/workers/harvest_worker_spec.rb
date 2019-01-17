# frozen_string_literal: true
require 'rails_helper'

describe HarvestWorker do
  let(:worker) { HarvestWorker.new }
  let(:parser) { Parser.new(strategy: 'xml', name: 'Natlib Pages', content: 'class NatlibPages < SupplejackCommon::Xml::Base; end', file_name: 'natlib_pages.rb', source: { source_id: 'source_id' }) }
  let(:job) { HarvestJob.new(environment: 'staging', parser_id: 'abc123') }

  before(:each) do
    SupplejackCommon.parser_base_path = Rails.root.to_s + '/tmp/parsers'
    allow(RestClient).to receive(:post)

    allow(worker).to receive(:job) { job }
    parser.load_file(:staging)
  end

  describe '#perform' do
    let!(:record) { double(:record, attributes: {}, valid?: true) }

    before(:each) do
      allow(job).to receive(:parser) { parser }
      allow(LoadedParser::Staging::NatlibPages).to receive(:records) { [record] }
      allow(worker).to receive(:api_update_finished?) { true }
      allow(worker).to receive(:process_record)
    end

    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'processes each record' do
      expect(worker).to receive(:process_record).with(record, job)
      worker.perform(1)
    end

    it 'enqueues enrichment jobs' do
      expect(job).to receive(:enqueue_enrichment_jobs)
      worker.perform(1)
    end

    it 'sets @job_id to the harvest_job_id' do
      worker.perform('abc123')
      expect(worker.job_id).to eq 'abc123'
    end

    it 'handles ids as objects' do
      worker.perform('$oid' => 'abc123')
      expect(worker.job_id).to eq 'abc123'
    end

    it 'calls finish!' do
      expect(job).to receive(:finish!)
      worker.perform('abc123')
    end
  end

  describe '#process_record' do
    let(:errors) { double(:errors, full_messages: []) }
    let(:record) { double(:record, attributes: { title: 'Hi', internal_identifier: ['record123'] }, valid?: true, raw_data: '</record>', errors: errors, full_raw_data: '</record>') }

    context 'record' do
      before do
        allow(record).to receive(:deletable?) { false }
        allow(job).to receive_message_chain(:parser, :source, :source_id) { 'source_id' }
        allow(job).to receive_message_chain(:parser, :data_type) { 'record' }
        allow(job).to receive_message_chain(:parser, :record?) { true }
        allow(job).to receive_message_chain(:parser, :id) { 1 }
        worker.instance_variable_set(:@source_id, 'source_id')
        allow(worker).to receive(:post_to_api)
      end

      it 'posts the record to the api with job_id' do
        expect(worker).to receive(:post_to_api).with(hash_including(title: 'Hi', internal_identifier: ['record123'], job_id: job.id.to_s))
        worker.process_record(record, job)
      end

      it 'posts the record to the api with source_id' do
        expect(worker).to receive(:post_to_api).with(hash_including(source_id: 'source_id'))
        worker.process_record(record, job)
      end

      it "doesn't post to the API on a test harvest" do
        allow(job).to receive(:test?) { true }
        expect(worker).not_to receive(:post_to_api).with(record)
        worker.process_record(record, job)
      end

      it 'increments records_count' do
        worker.process_record(record, job)
        expect(job.records_count).to eq 1
      end

      it 'saves the job' do
        expect(job).to receive(:save!)
        worker.process_record(record, job)
      end

      it "stores invalid record's raw data" do
        allow(record).to receive(:valid?) { false }
        allow(errors).to receive(:full_messages) { ["Title can't be blank"] }
        worker.process_record(record, job)
        expect(job.invalid_records.first.raw_data).to eq '</record>'
        expect(job.invalid_records.first.error_messages).to eq ["Title can't be blank"]
      end

      it 'rescues exceptions from a record and adds it to the failed records' do
        allow(worker).to receive(:post_to_api).and_raise 'Post failed'
        worker.process_record(record, job)
        expect(job.failed_records.first.message).to eq 'Post failed'
      end

      context 'deleteable record' do
        before { allow(record).to receive(:deletable?) { true } }

        it 'deletes_from_api if the record is deletable?' do
          expect(worker).to receive(:delete_from_api).with(['record123'])
          worker.process_record(record, job)
        end

        it 'does not post to api' do
          expect(worker).not_to receive(:post_to_api)
          worker.process_record(record, job)
        end
      end
    end

    context 'sidekiq_retries_exhausted' do
      before { allow(AbstractJob).to receive(:find).and_return(job) }
      before { allow(job).to receive(:parser) { parser } }

      it 'should update the end time' do
        worker.perform('abc123')

        described_class.within_sidekiq_retries_exhausted_block do
          expect(job).to receive(:update_attribute).twice
        end

        expect(job.end_time).to_not eq nil
        expect(job.end_time.day).to eq Time.zone.now.day
      end
    end

    context 'concept' do
      let(:record) { double(:record, attributes: { label: ['Colin John McCahon'], internal_identifier: ['record123'], match_concepts: :create_or_match }, valid?: true, errors: errors).as_null_object }
      let(:parser) { double(:parser, data_type: 'concept', concept?: true, record?: false).as_null_object }

      before do
        allow(record).to receive(:deletable?) { false }
        allow(job).to receive(:parser) { parser }
        worker.instance_variable_set(:@source_id, 'source_id')
        allow(worker).to receive(:post_to_api)
      end

      it 'should determine whether to create or match a concept' do
        expect(worker).to receive(:create_concept?).with(hash_including(label: ['Colin John McCahon'], internal_identifier: ['record123'], match_concepts: :create_or_match, source_id: 'source_id', data_type: 'concept'))
        worker.process_record(record, job)
      end
    end
  end

  describe '#post_to_api' do
    let(:attributes) { { title: 'Hi', data_type: 'record' } }

    before(:each) do
      allow(job).to receive(:required_enrichments)
    end

    it 'should post to the API' do
      worker.post_to_api(attributes)
      expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records.json', { 'record' => { 'title' => 'Hi' }, 'required_fragments' => nil }, job.id.to_s)
    end

    it 'should not post the data_type attribute to the API' do
      allow(ApiUpdateWorker).to receive(:perform_async)
      allow(attributes).to receive(:delete)

      expect(attributes).to receive(:delete).with(:data_type)
      worker.post_to_api(attributes)
    end

    it 'should not post the match_concepts attribute to the API' do
      allow(ApiUpdateWorker).to receive(:perform_async)
      allow(attributes).to receive(:delete)

      expect(attributes).to receive(:delete).with(:match_concepts)
      worker.post_to_api(attributes)
    end

    context 'data_type' do
      it 'should post to the (imaginary) Widget API with a widget data_type' do
        worker.post_to_api(title: 'Hi', data_type: 'widget')
        expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/widgets.json', { 'widget' => { 'title' => 'Hi' }, 'required_fragments' => nil }, job.id.to_s)
      end

      it 'should post to the Records API with no data_type' do
        worker.post_to_api(title: 'Hi')
        expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records.json', { 'record' => { 'title' => 'Hi' }, 'required_fragments' => nil }, job.id.to_s)
      end

      it 'should post to the Records API with an invalid data_type' do
        worker.post_to_api(title: 'Hi', data_type: nil)
        expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records.json', { 'record' => { 'title' => 'Hi' }, 'required_fragments' => nil }, job.id.to_s)
      end
    end

    context 'async false' do
      let(:api_update_worker) { double(:api_update_worker) }

      it 'should create a new instance of ApiUpdateWorker' do
        allow(job).to receive(:required_enrichments)
        expect(ApiUpdateWorker).to receive(:new) { api_update_worker }
        expect(api_update_worker).to receive(:perform)
        worker.post_to_api(attributes, false)
      end
    end

    context 'required fragments' do
      it 'should send the required enricments to the api' do
        allow(job).to receive(:required_enrichments) { [:ndha_rights] }
        worker.post_to_api(attributes)
        expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records.json', { 'record' => { 'title' => 'Hi' }, 'required_fragments' => ['ndha_rights'] }, job.id.to_s)
      end
    end
  end

  describe '#delete_from_api' do
    it 'should send a delete to the api' do
      worker.delete_from_api(['abc123'])
      expect(ApiDeleteWorker).to have_enqueued_sidekiq_job('abc123', job.id.to_s)
    end
  end
end
