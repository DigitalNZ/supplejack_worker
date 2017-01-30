# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

describe AbstractWorker do

  let(:worker) { AbstractWorker.new }
  let(:job) { FactoryGirl.create(:harvest_job) }

  before { AbstractJob.stub(:find) { job } }

  describe "#stop_harvest?" do
    before { job.stub(:enqueue_enrichment_jobs) { nil }  }
    
    context "status is stopped" do
      let(:job) { FactoryGirl.create(:harvest_job, status: "stopped") }

      it "returns true" do
        worker.stop_harvest?.should be_true
      end

      it "updates the job with the end time" do
        job.should_receive(:finish!)
        worker.stop_harvest?
      end

      it "returns true true when errors over limit" do
        job.stub(:errors_over_limit?) { true }
        worker.stop_harvest?.should be_true
      end
    end

    context "status is finished" do
      let(:job) { FactoryGirl.create(:harvest_job, status: "finished") }

      it "returns true" do
        worker.stop_harvest?.should be_true
      end

      it "should not finsihed the job (again)" do
        job.should_not_receive(:finish!)
        worker.stop_harvest?
      end
    end

    context "status is active" do
      let(:job) { FactoryGirl.create(:harvest_job, status: "active") }

      it "returns true when errors over limit" do
        job.stub(:errors_over_limit?) { true }
        worker.stop_harvest?.should be_true
      end

      it "returns false" do
        worker.stop_harvest?.should be_false
      end
    end
  end

  describe "#api_update_finished?" do
    
    it "should return true if the api update is finished" do
      job.stub(:posted_records_count) { 100 }
      job.stub(:records_count) { 100 }
      worker.send(:api_update_finished?).should be_true
    end

    it "should return false if the api update is not finished" do
      job.stub(:posted_records_count) { 10 }
      job.stub(:records_count) { 100 }
      worker.send(:api_update_finished?).should be_false
    end

    it "should reload the enrichment job" do
      job.should_receive(:reload)
      worker.send(:api_update_finished?)
    end
  end

  describe "#sanitize_id" do
    it "accepts strings and returns the string" do
      worker.send(:sanitize_id, "abc").should eq "abc"
    end

    it "it accepts serialized object_ids and returns the id string" do
      worker.send(:sanitize_id, {"$oid" => "preview123"}).should eq "preview123"
    end
  end

  describe "#job" do
    it "should find the job" do
      worker.instance_variable_set(:@job_id, 123)
      AbstractJob.should_receive(:find).with("123") { job }
      worker.job.should eq job
    end

    it "memoizes the result" do
      AbstractJob.should_receive(:find).once
      worker.job
      worker.job
    end
  end
end