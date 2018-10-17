# frozen_string_literal: true
require 'rails_helper'

describe EnrichmentWorker do
  class TestClass
    class_attribute :environment
    def self.get_source_id
      'nlnzcat'
    end
  end

  let(:worker) { EnrichmentWorker.new }
  let(:job) { create(:enrichment_job, environment: 'production', enrichment: 'ndha_rights') }
  let(:parser) { double(:parser, enrichment_definitions: { ndha_rights: { required_for_active_record: true } }, loader: double(:loader, parser_class: TestClass)).as_null_object }
  let(:records_response) { {
    records: [{id: '5a81fa176a694240d94c9592',fragments: [{ priority: 1, locations: %w[a b] },{ priority: 0, locations: %w[c d] }]}],
    meta: { page: 1, total_pages: 1}
  }.to_json }
  before(:each) do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/harvester/records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Bfragments.job_id%5D=#{job.harvest_job.id.to_s}&search_options%5Bpage%5D=1", {'Accept'=>'application/json'}, records_response, 201
    end

    allow(job).to receive(:parser) { parser }
    allow(worker).to receive(:job) { job }
    allow(worker).to receive(:api_update_finished?) { true }
  end

  describe '#perform' do
    before(:each) do
      worker.send(:setup_parser)
      allow(job).to receive_message_chain(:parser, :source, :source_id) { 'nlnzcat' }
    end

    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'should set the @job_id as a string' do
      worker.perform(1234)
      expect(worker.instance_variable_get('@job_id')).to eq '1234'
    end

    it 'should mark the job as started' do
      expect(job).to receive(:start!)
      worker.perform(1234)
    end

    it 'should setup the parser' do
      expect(worker).to receive(:setup_parser).and_call_original
      worker.perform(1234)
    end

    it 'should process every record' do
      worker.fetch_records(1).each do |record|
        expect(worker).to receive(:process_record).with(record)
      end
      worker.perform(1234)
    end

    it 'should finish the enrichment_job' do
      expect(job).to receive(:finish!)
      worker.perform(1234)
    end

    it 'stops processing the records' do
      allow(worker).to receive(:stop_harvest?) { true }
      expect(worker).not_to receive(:process_record)
      worker.perform(1)
    end

    it 'should check the api update has finished' do
      expect(worker).to receive(:api_update_finished?)
      worker.perform(1)
    end

    context 'paginated records response' do
      before do
        page_1_records_response = {
          records: [
            { id: '5a81fa176a694240d94c9592', fragments: [
              { priority: 1, locations: %w[a b] },
              { priority: 0, locations: %w[c d] }
            ] }
          ],
          meta: { page: 1, total_pages: 2}
        }.to_json
        page_2_records_response = {
          records: [
            { id: '5a81fa177a694240d94c9592', fragments: [
              { priority: 1, locations: %w[a b] },
              { priority: 0, locations: %w[c d] }
            ] }
          ],
          meta: { page: 2, total_pages: 2}
        }.to_json

        ActiveResource::HttpMock.respond_to do |mock|
          mock.get "/harvester/records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Bfragments.job_id%5D=#{job.harvest_job.id.to_s}&search_options%5Bpage%5D=1", {'Accept'=>'application/json'}, page_1_records_response, 201
          mock.get "/harvester/records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Bfragments.job_id%5D=#{job.harvest_job.id.to_s}&search_options%5Bpage%5D=2", {'Accept'=>'application/json'}, page_2_records_response, 201
        end
      end

      it 'calls #fetch_records for each page' do
        expect(worker).to receive(:fetch_records).twice.and_call_original
        worker.perform(1234)
      end
    end
  end

  describe '#fetch_records' do
    before(:each) do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/harvester/records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Bfragments.source_id%5D=nlnzcat&search_options&search_options%5Bpage%5D=1", {'Accept'=>'application/json'}, records_response, 201
      end

      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/harvester/records.json?api_key=#{ENV['HARVESTER_API_KEY']}&search%5Bfragments.job_id%5D=abc123&search_options&search_options%5Bpage%5D=1", {'Accept'=>'application/json'}, records_response, 201
      end

      worker.send(:setup_parser)
      allow(job).to receive_message_chain(:parser, :source, :source_id) { 'nlnzcat' }
    end

    it 'should fetch records based on the source_id' do
      worker.job.harvest_job = nil
      expect(SupplejackApi::Record).to receive(:find).with({ 'fragments.source_id' => 'nlnzcat' }, page: 1)
      worker.fetch_records(1)
    end

    context 'enrichment job has a relationship to a harvest job' do
      before do
        allow(job).to receive(:harvest_job) { double(:harvest_job, id: 'abc123') }
      end

      it 'only returns records with a fragment containing harvest job\'s id' do
        expect(SupplejackApi::Record).to receive(:find).with({ 'fragments.job_id' => 'abc123' }, page: 1)
        worker.fetch_records(1)
      end
    end

    context 'record_id is set' do
      before { allow(job).to receive(:record_id) { 'abc123' } }

      it 'should fetch a specific record' do
        expect(SupplejackApi::Record).to receive(:find).with({ record_id: job.record_id }, page: 1)
        worker.fetch_records(1)
      end

      context 'preview environment' do
        before { allow(job).to receive(:preview?) { true } }

        it 'should fetch a specific record from the preview_records collection' do
          expect(SupplejackApi::PreviewRecord).to receive(:find).with({record_id: job.record_id}, page: 0)
          worker.fetch_records
        end
      end
    end
  end

  describe '#process_record' do
    let(:record) { double(:record).as_null_object }
    let(:enrichment) { double(:enrichment, errors: []).as_null_object }

    before do
      worker.send(:setup_parser)
      allow(parser).to receive(:enrichment_definitions) { { ndha_rights: {} } }
      allow(SupplejackCommon::Enrichment).to receive(:new) { enrichment }
      allow(worker).to receive(:post_to_api) { nil }
    end

    it 'should initialize a enrichment' do
      expect(SupplejackCommon::Enrichment).to receive(:new).with('ndha_rights', worker.send(:enrichment_options), record, TestClass)
      worker.process_record(record)
    end

    it 'should call increment_processed_count!' do
      expect(worker.job).to receive(:increment_processed_count!)
      worker.process_record(record)
    end

    context 'enrichable' do
      before { allow(enrichment).to receive(:enrichable?) { true } }

      it 'should set the enrichment attributes' do
        expect(enrichment).to receive(:set_attribute_values)
        worker.process_record(record)
      end

      it 'should post to the api' do
        expect(worker).to receive(:post_to_api).with(enrichment)
        worker.process_record(record)
      end

      it 'should post to the api in a test environment' do
        allow(job).to receive(:test?) { true }
        expect(worker).not_to receive(:post_to_api).with(enrichment)
        worker.process_record(record)
      end

      it 'should rescue from a exception in processing the record' do
        allow(enrichment).to receive(:set_attribute_values).and_raise(StandardError.new('Hi'))
        worker.process_record(record)
      end
    end

    context 'not enrichable' do
      before { allow(enrichment).to receive(:enrichable?) { false } }

      it 'should not set the enrichment attributes' do
        expect(enrichment).not_to receive(:set_attribute_values)
        worker.process_record(record)
      end

      it 'should not post to the api' do
        expect(worker).not_to receive(:post_to_api).with(enrichment)
        worker.process_record(record)
      end

      it 'should not increment the records count on the job' do
        expect(job).not_to receive(:increment_records_count!)
        worker.process_record(record)
      end
    end
  end

  describe '#setup_parser' do
    it 'should initialize a parser' do
      worker.send(:setup_parser)
      expect(worker.parser).to eq parser
    end

    it 'should load the parser file' do
      expect(parser).to receive(:load_file)
      worker.send(:setup_parser)
    end

    it 'should initialize the parser class' do
      worker.send(:setup_parser)
      expect(worker.parser_class).to eq TestClass
    end

    it 'should set the environment of the job to the parser_class' do
      worker.send(:setup_parser)
      expect(worker.parser_class.environment).to eq 'production'
    end
  end

  describe '#enrichment_options' do
    let(:block) { proc { 'Hi' } }

    before(:each) do
      allow(parser).to receive(:enrichment_definitions) { { ndha_rights: { block: block } } }
    end

    it 'should fetch the enrichment definition options' do
      job.enrichment = 'ndha_rights'
      worker.send(:setup_parser)
      expect(worker.send(:enrichment_options)).to eq(block: block)
    end
  end

  describe '#enrichment_class' do
    let(:block) { proc { 'Hi' } }

    before(:each) do
      allow(parser).to receive(:enrichment_definitions) { { ndha_rights: { block: block } } }
      job.enrichment = 'ndha_rights'
      worker.send(:setup_parser)
    end

    it 'defaults to SupplejackCommon::Enrichment' do
      expect(worker.send(:enrichment_class)).to eq SupplejackCommon::Enrichment
    end
  end

  describe '#post_to_api' do
    let(:record) { double(:record, id: 123) }
    let(:enrichment) { double(:enrichment, record: record, record_attributes: { '1' => { title: 'foo' }, '2' => { category: 'books' } }) }

    it 'enqueues an ApiUpdate job with record_id, attributes (including job_id) and enrichment_job_id for each enriched record' do
      worker.send(:post_to_api, enrichment)
      expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records/2/fragments.json', { 'fragment' => { 'category' => 'books', 'job_id' => job.id.to_s }, 'required_fragments' => ['ndha_rights'] }, job.id.to_s)
      expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records/1/fragments.json', { 'fragment' => { 'title' => 'foo', 'job_id' => job.id.to_s }, 'required_fragments' => ['ndha_rights'] }, job.id.to_s)
    end

    it 'should increment the records count on the job' do
      expect(job).to receive(:increment_records_count!).twice
      worker.send(:post_to_api, enrichment)
    end

    context 'required fragments' do
      it 'should send the required enricments to the api' do
        allow(job).to receive(:required_enrichments) { ['ndha_rights'] }
        worker.send(:post_to_api, enrichment)
        expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/records/1/fragments.json', { 'fragment' => { 'title' => 'foo', 'job_id' => job.id.to_s }, 'required_fragments' => ['ndha_rights'] }, job.id.to_s)
      end
    end
  end
end
