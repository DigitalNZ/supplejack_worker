# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

describe HarvestJob do

  context "validations" do
    it "should not be possible to have 2 active jobs for the same parser/environment" do
      job1 = FactoryGirl.create(:harvest_job, parser_id: "333", environment: "staging", status: "active")
      job2 = FactoryGirl.build(:harvest_job, parser_id: "333", environment: "staging", status: "active")
      job2.should_not be_valid
    end

    it "should be possible to have 2 finished jobs for the same parser/environment" do
      job1 = FactoryGirl.create(:harvest_job, parser_id: "333", environment: "staging", status: "finished")
      job2 = FactoryGirl.build(:harvest_job, parser_id: "333", environment: "staging", status: "finished")
      job2.should be_valid
    end

    it "should be possible to enqueue a harvest and enrichment jobs simultaneously" do
      job = FactoryGirl.create(:harvest_job, parser_id: "333", environment: "staging", status: "active")
      enrichment = FactoryGirl.build(:enrichment_job, parser_id: "333", environment: "staging", status: "active")
      enrichment.should be_valid
    end

    it "should not be possible to have a mode other then 'normal', 'full_and_flush' or 'incremental'" do
      job1 = FactoryGirl.build(:harvest_job, parser_id: "333", mode: 'ya')
      job1.should_not be_valid
    end

    ['normal', 'full_and_flush', 'incremental'].each do |mode|
      it "should be valid with mode of '#{mode}'" do
        job1 = FactoryGirl.build(:harvest_job, parser_id: "333", mode: mode)
        job1.should be_valid
      end
    end
  end

  it "enqueues a job after_create" do
    HarvestWorker.should_receive(:perform_async)
    FactoryGirl.create(:harvest_job)
  end

  context "preview environment" do
    it "does not enque a job after create" do
      HarvestWorker.should_not_receive(:perform_async)
      FactoryGirl.create(:harvest_job, environment: "preview")
    end
  end

  let(:job) { FactoryGirl.create(:harvest_job, parser_id: "12345", version_id: "666") }

  describe "#enqueue_enrichment_jobs" do
    let(:parser) { double(:parser, enrichment_definitions: {ndha_rights: Proc.new{} }).as_null_object }

    before do
      job.stub(:parser) { parser }
    end

    it "enqueues a enrichment job for each enrichment" do
      job.enrichments = ["ndha_rights"]
      EnrichmentJob.should_receive(:create_from_harvest_job).with(job, :ndha_rights)
      job.enqueue_enrichment_jobs
    end

    it "should not enqueue enrichments not specified in the job" do
      job.enrichments = []
      EnrichmentJob.should_not_receive(:create_from_harvest_job)
      job.enqueue_enrichment_jobs
    end
  end

  describe "#flush_old_records" do
    it "should post to the apis /harvester/records/flush action with source_id and the harvest_job_id" do
      job.stub(:source_id) {'tapuhi'}
      RestClient.should_receive(:post).with("#{ENV['API_HOST']}/harvester/records/flush.json", {source_id: 'tapuhi', job_id: job.id, api_key: ENV['HARVESTER_API_KEY']})
      job.flush_old_records
    end
  end

  describe "records" do

    let(:parser) { Parser.new(strategy: "xml", name: "Natlib Pages", content: "class NatlibPages < SupplejackCommon::Xml::Base; end", file_name: "natlib_pages.rb") }
    let(:record1) { double(:record) }
    let(:record2) { double(:record) }

    before do
      SupplejackCommon.parser_base_path = Rails.root.to_s + "/tmp/parsers"
      parser.load_file("staging")

      job.stub(:environment) { "staging" }
      job.stub(:parser) { parser }
      job.stub(:finish!)
      job.stub(:start!)

      LoadedParser::Staging::NatlibPages.stub(:environment=).with("staging")
      LoadedParser::Staging::NatlibPages.stub(:records) { [record1, record2] }
    end

    it "should start the job" do
      job.records {|r| r }
      expect(job).to have_received(:start!)
    end

    it "gets records from parser class" do
      job.records {|r| r }
      expect(LoadedParser::Staging::NatlibPages).to have_received(:records)
    end

    it "rescues exceptions from the whole harvest and stores it" do
      LoadedParser::Staging::NatlibPages.stub(:records).and_raise "Everything broke"
      job.records {|r| r }
      job.harvest_failure.message.should eq "Everything broke"
    end

    it "yields each record with index" do
      expect { |b| job.records(&b) }.to yield_successive_args([record1,0], [record2,1])
    end
  end

  describe "#finish!" do
    before do 
      job.mode = 'full_and_flush'
    end

    it "flushes old records if full_and_flush is true" do
      job.should_receive(:flush_old_records)
      job.finish!
    end

    it "does not flush record if full_and_flush is false" do
      job.mode = 'normal'
      job.should_not_receive(:flush_old_records)
      job.finish!
    end

    it "does not flush record if limit is set" do
      job.limit = 100
      job.should_not_receive(:flush_old_records)
      job.finish!
    end

    it "does not flush records if a harvest failure occured" do
      job.build_harvest_failure()
      job.should_not_receive(:flush_old_records)
      job.finish!
    end

    it "does not flush record if the job is manually stopped" do
      job.status = 'stopped'
      job.should_not_receive(:flush_old_records)
      job.finish!
    end
  end
end
