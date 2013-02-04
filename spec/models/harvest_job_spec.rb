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

  describe "calculate_average_record_time" do
    before(:each) do
      job.end_time = Time.now
    end

    it "should calculate the average record time" do
      job.records_harvested = 100
      job.stub(:duration) { 100 }
      job.calculate_average_record_time
      job.average_record_time.should eq 1.0
    end
  end

  describe "#duration" do
    let!(:time) { Time.now }

    it "should return the duration in seconds" do
      job.start_time = time - 10.seconds
      job.end_time = time
      job.save
      job.reload
      job.duration.should eq 10.0
    end

    it "returns nil start_time is nil" do
      job.start_time = nil
      job.duration.should be_nil
    end

    it "returns nil end_time is nil" do
      job.end_time = nil
      job.duration.should be_nil
    end
  end

end