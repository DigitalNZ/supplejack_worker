require "spec_helper"

describe EnrichmentJob do
    
  let(:job) { FactoryGirl.create(:harvest_job, parser_id: "12345", version_id: "666", user_id: "1", environment: "staging") }

  context "validations" do
    it "should not be possible to have 2 active jobs for the same enrichment/parser/environment" do
      job1 = FactoryGirl.create(:enrichment_job, enrichment: "tapuhi_relationships", parser_id: "333", environment: "staging", status: "active")
      job2 = FactoryGirl.build(:enrichment_job, enrichment: "tapuhi_relationships", parser_id: "333", environment: "staging", status: "active")
      job2.should_not be_valid
    end

    it "should be possible to have 2 finished jobs for the same enrichment/parser/environment" do
      job1 = FactoryGirl.create(:enrichment_job, enrichment: "tapuhi_relationships", parser_id: "333", environment: "staging", status: "finished")
      job2 = FactoryGirl.build(:enrichment_job, enrichment: "tapuhi_relationships", parser_id: "333", environment: "staging", status: "finished")
      job2.should be_valid
    end

    it "should be possible to have 2 active jobs with the same parser/environment" do
      job1 = FactoryGirl.create(:enrichment_job, enrichment: "tapuhi_relationships", parser_id: "333", environment: "staging", status: "active")
      job2 = FactoryGirl.build(:enrichment_job, enrichment: "tapuhi_denormalization", parser_id: "333", environment: "staging", status: "active")
      job2.should be_valid
    end
  end

  describe ".create_from_harvest_job" do

    subject { EnrichmentJob.create_from_harvest_job(job, :ndha_rights) }

    its(:parser_id) { should eq "12345" }
    its(:version_id) { should eq "666" }
    its(:user_id) { should eq "1" }
    its(:environment) { should eq "staging" }
    its(:harvest_job_id) { should eq job.id }
    its(:enrichment) { should eq "ndha_rights" }
  end

  describe "#enqueue" do
    it "should enqueue a EnrichmentWorker" do
      EnrichmentWorker.should_receive(:perform_async)
      EnrichmentJob.create_from_harvest_job(job, :ndha_rights)
    end
  end

  context "preview environment" do

    before {job.environment = "preview"}
    
    it "does not enque a job after create" do
      EnrichmentWorker.should_not_receive(:perform_async)
      EnrichmentJob.create_from_harvest_job(job, :ndha_rights)
    end
  end
end