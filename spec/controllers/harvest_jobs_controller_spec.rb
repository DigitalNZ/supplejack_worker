require "spec_helper"

describe HarvestJobsController do

  let(:job) { mock_model(HarvestJob).as_null_object }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
  end

  describe "GET index" do
    let(:jobs) { [job] }

    before(:each) do
      HarvestJob.stub(:search) { jobs }
      jobs.stub(:http) { {} }
      jobs.stub(:total_count) { 45 }
      jobs.stub(:offset_value) { 0 }
      jobs.stub(:limit_value) { 20 }
    end

    it "returns active harvest jobs" do
      HarvestJob.should_receive(:search).with(hash_including("status" => "active"))
      get :index, status: "active"
    end

    it "should set pagination headers" do
      get :index, status: "active"
      response.headers["X-total"].should eq "45"
      response.headers["X-offset"].should eq "0"
      response.headers["X-limit"].should eq "20"
    end
  end
  
  describe "POST create" do
    before(:each) do
      HarvestJob.stub(:new) { job }
    end

    it "initializes a new harvest job" do
      HarvestJob.should_receive(:new).with({"strategy" => "xml", "file_name" => "youtube.rb"}) { job }
      post :create, harvest_job: {strategy: "xml", file_name: "youtube.rb"}, format: "js"
      assigns(:harvest_job).should eq job
    end

    it "should save the harvest job" do
      job.should_receive(:save)
      post :create, harvest_job: {strategy: "xml", file_name: "youtube.rb"}, format: "js"
    end
  end

  describe "#GET show" do
    
    it "finds the harvest job" do
      HarvestJob.should_receive(:find).with("1") { job }
      get :show, id: 1, format: "js"
      assigns(:harvest_job).should eq job
    end
  end

  describe "PUT Update" do
    before(:each) do
      HarvestJob.stub(:find).with("1") { job }
    end

    it "finds the harvest job" do
      HarvestJob.should_receive(:find).with("1") { job }
      put :update, id: 1, format: "js"
      assigns(:harvest_job).should eq job
    end

    it "should update the attributes" do
      job.should_receive(:update_attributes).with({"stop" => true})
      put :update, id: 1, harvest_job: {stop: true}, format: "js"
    end
  end
end