require 'spec_helper'

describe LinkCheckJobsController do

  describe "POST create" do
    let(:link_check) { double(:link_check) }

    it "should create a link_check_job" do
      LinkCheckJob.should_receive(:create).with({'url' => 'http://google.co.nz', 'primary_collection' => 'TAPUHI'}) { link_check }
      post :create, { link_check: {url: "http://google.co.nz", primary_collection: 'TAPUHI' } }
      assigns(:link_check).should eq link_check
    end
  end

end
