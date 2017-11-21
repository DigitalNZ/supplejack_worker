# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe LinkCheckJobsController do
  describe 'POST create' do
    let(:link_check_job) { create(:link_check_job) }

    it 'should create a link_check_job' do
      params = ActionController::Parameters.new('url' => 'http://google.co.nz', 'source_id' => 'source_id', record_id: '123').permit!
      LinkCheckJob.should_receive(:create!).with(params) { link_check_job }
      post :create, params: { link_check: { url: 'http://google.co.nz', source_id: 'source_id', record_id: '123' } }
      assigns(:link_check).should eq link_check_job
    end
  end
end
