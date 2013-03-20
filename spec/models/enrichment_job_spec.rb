require "spec_helper"

describe EnrichmentJob do
    
  let(:job) { FactoryGirl.create(:harvest_job, parser_id: "12345", version_id: "666", user_id: "1", environment: "staging") }

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
end