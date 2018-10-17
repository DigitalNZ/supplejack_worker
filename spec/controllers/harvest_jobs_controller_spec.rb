# frozen_string_literal: true
require 'rails_helper'

describe HarvestJobsController do
  let(:job) { double(:harvest_job, save: true, update: true) }

  describe 'authorized requests' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
    end

    describe 'POST create' do
      before(:each) do
        allow(HarvestJob).to receive(:new).and_return(job)
      end

      it 'initializes a new harvest job' do
        params = ActionController::Parameters.new(strategy: 'xml', file_name: 'youtube.rb').permit!
        expect(HarvestJob).to receive(:new).with(params).and_return(job)
        post :create, params: { harvest_job: { strategy: 'xml', file_name: 'youtube.rb' } }, format: 'js'
        expect(assigns(:harvest_job)).to eq job
      end

      it 'saves the harvest job' do
        expect(job).to receive(:save)
        post :create, params: { harvest_job: { strategy: 'xml', file_name: 'youtube.rb' } }, format: 'js'
      end
    end

    describe '#GET show' do
      it 'finds the harvest job' do
        expect(HarvestJob).to receive(:find).with('1').and_return(job)
        get :show, params: { id: 1 }, format: 'js'
        expect(assigns(:harvest_job)).to eq job
      end
    end

    describe 'PUT Update' do
      before(:each) do
        allow(HarvestJob).to receive(:find).with('1').and_return(job)
      end

      it 'finds the harvest job' do
        expect(HarvestJob).to receive(:find).with('1').and_return(job)
        put :update, params: { id: 1, harvest_job: { stop: true } }, format: 'js'
        expect(assigns(:harvest_job)).to eq job
      end

      it 'updates the attributes' do
        params = ActionController::Parameters.new(stop: 'true').permit!
        expect(job).to receive(:update).with(params)
        put :update, params: { id: 1, harvest_job: { stop: true } }, format: 'js'
      end
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
