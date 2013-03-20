require "spec_helper"

describe AbstractJobsController do

  let(:job) { mock_model(AbstractJob).as_null_object }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
  end

  describe "GET index" do
    let(:jobs) { [job] }

    before(:each) do
      AbstractJob.stub(:search) { jobs }
      jobs.stub(:http) { {} }
      jobs.stub(:total_count) { 45 }
      jobs.stub(:offset_value) { 0 }
      jobs.stub(:limit_value) { 20 }
    end

    it "returns active abstract jobs" do
      AbstractJob.should_receive(:search).with(hash_including("status" => "active"))
      get :index, status: "active"
    end

    it "should set pagination headers" do
      get :index, status: "active"
      response.headers["X-total"].should eq "45"
      response.headers["X-offset"].should eq "0"
      response.headers["X-limit"].should eq "20"
    end
  end
end