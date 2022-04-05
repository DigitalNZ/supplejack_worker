# frozen_string_literal: true

require 'rails_helper'

describe AbstractJobsController do
  describe 'GET index' do
    context 'when worker_key is not provided' do
      it 'returns unauthorized' do
        get :index, params: { status: 'active' }

        expect(response).to be_unauthorized
      end
    end

    context 'when worker_key is provided' do
      before do
        request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

        allow(AbstractJob)
          .to receive(:search)
          .and_return(double(total_count: 45, offset_value: 0, limit_value: 20))
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
  end
end
