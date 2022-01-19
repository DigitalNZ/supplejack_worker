# frozen_string_literal: true

require 'rails_helper'

describe LinkCheckJobsController do
  describe 'POST create' do
    context 'when job with same record_id dosent not exist' do
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

    context 'when job with same record_id exists' do
      let!(:job) { create(:link_check_job) }

      before do
        attributes = attributes_for(:link_check_job)
        attributes[:record_id] = job.record_id

        post :create, params: { link_check: attributes }
      end

      it 'is unsuccessful' do
        expect(response).to be_a_bad_request
      end

      it 'returns errors' do
        errors = JSON.parse(response.body)

        expect(errors).to eq({ 'errors' => ["Record Cannot create job for a #{job.record_id} twice in 6 hours"] })
      end
    end
  end
end
