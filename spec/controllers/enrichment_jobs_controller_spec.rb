require "spec_helper"

describe EnrichmentJobsController do

  let(:job) { mock_model(EnrichmentJob).as_null_object }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
  end
  
  describe "POST create" do
    before(:each) do
      EnrichmentJob.stub(:new) { job }
    end

    it "initializes a new enrichment job" do
      EnrichmentJob.should_receive(:new).with({"strategy" => "xml", "file_name" => "youtube.rb"}) { job }
      post :create, enrichment_job: {strategy: "xml", file_name: "youtube.rb"}, format: "js"
      assigns(:enrichment_job).should eq job
    end

    it "should save the enrichment job" do
      job.should_receive(:save)
      post :create, enrichment_job: {strategy: "xml", file_name: "youtube.rb"}, format: "js"
    end
  end

  describe "#GET show" do
    
    it "finds the enrichment job" do
      EnrichmentJob.should_receive(:find).with("1") { job }
      get :show, id: 1, format: "js"
      assigns(:enrichment_job).should eq job
    end
  end

  describe "PUT Update" do
    before(:each) do
      EnrichmentJob.stub(:find).with("1") { job }
    end

    it "finds the enrichment job" do
      EnrichmentJob.should_receive(:find).with("1") { job }
      put :update, id: 1, format: "js"
      assigns(:enrichment_job).should eq job
    end

    it "should update the attributes" do
      job.should_receive(:update_attributes).with({"stop" => true})
      put :update, id: 1, enrichment_job: {stop: true}, format: "js"
    end
  end
end