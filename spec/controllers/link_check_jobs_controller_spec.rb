# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

describe LinkCheckJobsController do

  describe "POST create" do
    let(:link_check_job) { create(:link_check_job) }

    it "should create a link_check_job" do
      LinkCheckJob.should_receive(:create).with({'url' => 'http://google.co.nz', 'source_id' => 'tapuhi'}) { link_check_job }
      post :create, { link_check: {url: "http://google.co.nz", source_id: 'tapuhi' } }
      assigns(:link_check).should eq link_check_job
    end
  end

end
