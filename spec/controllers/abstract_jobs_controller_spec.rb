# frozen_string_literal: true

require 'rails_helper'

describe AbstractJobsController do
  describe 'GET index' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
      mock_obj = double(total_count: 45, offset_value: 0, limit_value: 20)
      allow(AbstractJob).to receive(:search).and_return(mock_obj)
    end

    it 'returns active abstract jobs' do
      allow(AbstractJob).to receive(:search).with(
        hash_including('status' => 'active')
      ).and_call_original
      get :index, params: { status: 'active' }
    end

    it 'should set pagination headers' do
      get :index, params: { status: 'active' }
      expect(response.headers['X-total']).to eq '45'
      expect(response.headers['X-offset']).to eq '0'
      expect(response.headers['X-limit']).to eq '20'
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
