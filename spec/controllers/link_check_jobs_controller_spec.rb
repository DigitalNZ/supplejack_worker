# frozen_string_literal: true

require 'rails_helper'

describe LinkCheckJobsController do
  describe 'POST create' do
    let(:link_check_job) { create(:link_check_job) }

    it 'should create a link_check_job' do
      params = ActionController::Parameters.new('url' => 'http://google.co.nz', 'source_id' => 'source_id', record_id: '123').permit!
      allow(LinkCheckJob).to receive(:create!).with(params).and_return(link_check_job)
      post :create, params: { link_check: { url: 'http://google.co.nz', source_id: 'source_id', record_id: '123' } }
      expect(assigns(:link_check)).to eq link_check_job
    end
  end
end
