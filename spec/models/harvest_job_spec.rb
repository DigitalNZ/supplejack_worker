require "spec_helper"

describe HarvestJob do
  
  it "enqueues a job after_create" do
    HarvestWorker.should_receive(:perform_async)
    HarvestJob.create
  end

  let(:job) { FactoryGirl.build(:harvest_job, parser_id: "12345") }

  describe "#parser" do
    it "finds the parser by id" do
      Parser.should_receive(:find).with("12345")
      job.parser
    end
  end

  describe "#finished?" do
    it "returns true with a end_time" do
      job.end_time = Time.now
      job.finished?.should be_true
    end

    it "returns false without a end_time" do
      job.end_time = nil
      job.finished?.should be_false
    end
  end

end