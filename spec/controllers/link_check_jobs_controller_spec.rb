# frozen_string_literal: true

require 'rails_helper'

describe LinkCheckJobsController do
  describe 'POST create' do
    let(:attributes) { attributes_for(:link_check_job) }

    before do
      # This will stop it from running a sidekiq job
      ENV['LINK_CHECKING_ENABLED'] == 'true'
      post :create, params: { link_check: attributes }
    end

    it 'is successful' do
      expect(response).to be_successful
    end

    it 'has a new link check job' do
      job = LinkCheckJob.last

      expect(job.url).to eq attributes[:url]
      expect(job.record_id).to eq attributes[:record_id]
      expect(job.source_id).to eq attributes[:source_id]
    end
  end
end
