require "spec_helper"

describe HarvestJob do
  
  it "enqueues a job after_create" do
    HarvestWorker.should_receive(:perform_async)
    HarvestJob.create
  end

  let(:job) { FactoryGirl.create(:harvest_job, parser_id: "12345", version_id: "666") }

  describe ".search" do
    let!(:active_job) { FactoryGirl.create(:harvest_job, status: "active") }

    it "returns all active harvest jobs" do
      finished_job = FactoryGirl.create(:harvest_job, status: "finished")
      HarvestJob.search("status" => "active").should eq [active_job]
    end

    it "paginates through the records" do
      active_job2 = FactoryGirl.create(:harvest_job, status: "active", start_time: Time.now)
      HarvestJob.paginates_per 1
      HarvestJob.search("status" => "active", "page" => 2).should eq [active_job]
    end

    it "returns the recent harvest jobs first" do
      active_job2 = FactoryGirl.create(:harvest_job, status: "active", start_time: Time.now + 5.seconds)
      HarvestJob.search("status" => "active").first.should eq active_job2
    end
  end

  describe "#parser" do
    it "finds the parser by id" do
      Parser.should_receive(:find).with("666", params: {parser_id: "12345"})
      job.parser
    end
  end

  describe "#start!" do
    it "sets the status to active" do
      job.start!
      job.reload
      job.status.should eq "active"
    end

    it "sets the start_time" do
      time = Time.now
      Timecop.freeze(time) do
        job.start!
        job.reload
        job.start_time.to_i.should eq time.to_i
      end
    end
  end

  describe "#finish!" do
    it "sets the status to finished" do
      job.finish!
      job.reload
      job.status.should eq "finished"
    end

    it "sets the end_time" do
      time = Time.now
      Timecop.freeze(time) do
        job.finish!
        job.reload
        job.end_time.to_i.should eq time.to_i
      end
    end
  end

  describe "#finished?" do
    it "returns true" do
      job.status = "finished"
      job.finished?.should be_true
    end

    it "returns false" do
      job.status = "active"
      job.finished?.should be_false
    end
  end

  describe "#stopped?" do
    it "returns true" do
      job.status = "stopped"
      job.stopped?.should be_true
    end

    it "returns false" do
      job.status = "finished"
      job.stopped?.should be_false
    end
  end

  describe "calculate_average_record_time" do
    before(:each) do
      job.end_time = Time.now
      job.status = "finished"
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