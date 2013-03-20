require "spec_helper"

describe HarvestJob do
  
  it "enqueues a job after_create" do
    HarvestWorker.should_receive(:perform_async)
    FactoryGirl.create(:harvest_job)
  end

  let(:job) { FactoryGirl.create(:harvest_job, parser_id: "12345", version_id: "666") }

  describe "#finish!" do
    let(:parser) { mock(:parser, enrichment_definitions: {}).as_null_object }

    before do
      job.stub(:parser) { parser }
    end

    it "enqueues enrichment jobs" do
      job.should_receive(:enqueue_enrichment_jobs)
      job.finish!
    end
  end

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

end