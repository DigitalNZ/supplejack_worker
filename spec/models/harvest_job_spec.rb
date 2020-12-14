# frozen_string_literal: true

require 'rails_helper'

describe HarvestJob do
  context 'validations' do
    it 'is not possible to have 2 active jobs for the same parser/environment' do
      create(:harvest_job, parser_id: '333', environment: 'staging', status: 'active')
      job2 = build(:harvest_job, parser_id: '333', environment: 'staging', status: 'active')
      expect(job2).to_not be_valid
    end

    it 'is possible to have 2 finished jobs for the same parser/environment' do
      create(:harvest_job, parser_id: '333', environment: 'staging', status: 'finished')
      job2 = build(:harvest_job, parser_id: '333', environment: 'staging', status: 'finished')
      expect(job2).to be_valid
    end

    it 'is possible to enqueue a harvest and enrichment jobs simultaneously' do
      create(:harvest_job, parser_id: '333', environment: 'staging', status: 'active')
      enrichment = build(:enrichment_job, parser_id: '333', environment: 'staging', status: 'active')
      expect(enrichment).to be_valid
    end

    it "is not possible to have a mode other then 'normal', 'full_and_flush' or 'incremental'" do
      job1 = build(:harvest_job, parser_id: '333', mode: 'ya')
      expect(job1).to_not be_valid
    end

    %w[normal full_and_flush incremental].each do |mode|
      it "is valid with mode of '#{mode}'" do
        job1 = build(:harvest_job, parser_id: '333', mode: mode)
        expect(job1).to be_valid
      end
    end
  end

  it 'enqueues a job after_create' do
    expect(HarvestWorker).to receive(:perform_async)
    create(:harvest_job)
  end

  context 'preview environment' do
    it 'does not enque a job after create' do
      expect(HarvestWorker).to_not receive(:perform_async)
      create(:harvest_job, environment: 'preview')
    end
  end

  let(:job) { create(:harvest_job, parser_id: '12345', version_id: '666') }

  describe '#enqueue_enrichment_jobs' do
    let(:parser) { double(:parser, enrichment_definitions: { ndha_rights: proc { } }).as_null_object }

    before do
      allow(job).to receive(:parser).and_return(parser)
    end

    it 'enqueues a enrichment job for each enrichment' do
      job.enrichments = ['ndha_rights']
      expect(EnrichmentJob).to receive(:create_from_harvest_job).with(job, :ndha_rights)
      job.enqueue_enrichment_jobs
    end

    it 'should not enqueue enrichments not specified in the job' do
      job.enrichments = []
      expect(EnrichmentJob).to_not receive(:create_from_harvest_job)
      job.enqueue_enrichment_jobs
    end
  end

  describe '#flush_old_records' do
    it 'post to the apis /harvester/records/flush action with source_id and the harvest_job_id' do
      allow(job).to receive(:source_id).and_return('source_id')
      expect(RestClient).to receive(:post).with("#{ENV['API_HOST']}/harvester/records/flush.json", source_id: 'source_id', job_id: job.id,
api_key: ENV['HARVESTER_API_KEY'])
      job.flush_old_records
    end
  end

  describe 'records' do
    let(:parser) {
 Parser.new(strategy: 'xml', name: 'Natlib Pages', content: 'class NatlibPages < SupplejackCommon::Xml::Base; end', file_name: 'natlib_pages.rb') }
    let(:record1) { double(:record) }
    let(:record2) { double(:record) }

    before do
      SupplejackCommon.parser_base_path = Rails.root.to_s + '/tmp/parsers'
      parser.load_file('staging')

      allow(job).to receive(:environment).and_return('staging')
      allow(job).to receive(:parser).and_return(parser)
      allow(job).to receive(:finish!)
      allow(job).to receive(:start!)

      allow(LoadedParser::Staging::NatlibPages).to receive(:environment=).with('staging')
      allow(LoadedParser::Staging::NatlibPages).to receive(:records).and_return([record1, record2])
    end

    it 'starts the job' do
      job.records { |r| r }
      expect(job).to have_received(:start!)
    end

    it 'gets records from parser class' do
      job.records { |r| r }
      expect(LoadedParser::Staging::NatlibPages).to have_received(:records)
    end

    it 'rescues exceptions from the whole harvest and stores it' do
      allow(LoadedParser::Staging::NatlibPages).to receive(:records).and_raise 'Everything broke'
      job.records { |r| r }
      expect(job.harvest_failure.message).to eq 'Everything broke'
    end

    it 'yields each record with index' do
      expect { |b| job.records(&b) }.to yield_successive_args([record1, 0], [record2, 1])
    end
  end

  describe '#finish!' do
    before do
      job.mode = 'full_and_flush'
    end

    it 'flushes old records if full_and_flush is true' do
      job.records_count = 1
      expect(job).to receive(:flush_old_records)
      job.finish!
    end

    it 'does not flush record if full_and_flush is false' do
      job.mode = 'normal'
      expect(job).to_not receive(:flush_old_records)
      job.finish!
    end

    it 'does not flush record if limit is set' do
      job.limit = 100
      expect(job).to_not receive(:flush_old_records)
      job.finish!
    end

    it 'does not flush records if a harvest failure occured' do
      job.build_harvest_failure
      expect(job).to_not receive(:flush_old_records)
      job.finish!
    end

    it 'does not flush record if the job is manually stopped' do
      job.status = 'stopped'
      expect(job).to_not receive(:flush_old_records)
      job.finish!
    end
  end

  describe '#full_and_flush_available?' do
    let(:full_and_flush_job) {
 create(:harvest_job, parser_id: '12345', version_id: '666', records_count: 1, limit: 0, status: 'running', mode: 'full_and_flush') }
    let(:full_and_flush_job_with_no_records) {
 create(:harvest_job, parser_id: '12345', version_id: '666', records_count: 0, limit: 0, status: 'running', mode: 'full_and_flush') }

    it 'returns true when the requirements for a full and flush are valid' do
      expect(full_and_flush_job.full_and_flush_available?).to eq true
    end

    it 'returns false when the requirements for a full and flush are invalid' do
      expect(full_and_flush_job_with_no_records.full_and_flush_available?).to eq false
    end
  end
end
