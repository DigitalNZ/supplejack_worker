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
    let(:parser) { mock(:parser, enrichment_definitions: {ndha_rights: Proc.new{} }).as_null_object }

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
      RestClient.should_receive(:post).with("#{ENV['API_HOST']}/harvester/records/flush.json", {source_id: 'tapuhi', job_id: job.id})
      job.flush_old_records
    end
  end

  describe "#finish!" do 
    it "flushes old records if full_and_flush is true" do
      job.mode = 'full_and_flush'
      job.should_receive(:flush_old_records)
      job.finish!
    end

    it "does not flush record if full_and_flush is false" do
      job.mode = 'normal'
      job.should_not_receive(:flush_old_records)
      job.finish!
    end

    it "does not flush record if limit is set" do
      job.mode = 'full_and_flush'
      job.limit = 100
      job.should_not_receive(:flush_old_records)
      job.finish!
    end
  end
end