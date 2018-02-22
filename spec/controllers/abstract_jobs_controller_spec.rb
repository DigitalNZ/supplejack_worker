# frozen_string_literal: true
require 'rails_helper'

describe AbstractJobsController do

  describe 'GET index' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
      AbstractJob.stub(:search) do
        double(total_count: 45, offset_value: 0, limit_value: 20)
      end
    end

    it 'returns active abstract jobs' do
      AbstractJob.should_receive(:search).with(
        hash_including('status' => 'active')
      )
      get :index, params: { status: 'active' }
    end

    it 'should set pagination headers' do
      get :index, params: { status: 'active' }
      response.headers['X-total'].should eq '45'
      response.headers['X-offset'].should eq '0'
      response.headers['X-limit'].should eq '20'
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
