# frozen_string_literal: true
require 'rails_helper'

describe CollectionStatisticsController do
  let(:collection_statistic) { double(:collection_statistics) }

  describe 'GET index' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
    end

    it 'should get all of the collection statistics dates' do
      allow(CollectionStatistics).to receive(:all).and_return([collection_statistic])
      get :index
      expect(assigns(:collection_statistics)).to eq [collection_statistic]
    end

    it 'should get all of the collection statistics dates' do
      allow(CollectionStatistics).to receive(:where).with('day' => Date.today.to_s).and_return([collection_statistic])
      get :index, params: { collection_statistics: { day: Date.today.to_s } }
      expect(assigns(:collection_statistics)).to eq [collection_statistic]
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
