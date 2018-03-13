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
        HarvestJob.stub(:new) { job }
      end

      it 'initializes a new harvest job' do
        params = ActionController::Parameters.new(strategy: 'xml', file_name: 'youtube.rb').permit!
        HarvestJob.should_receive(:new).with(params) { job }
        post :create, params: { harvest_job: { strategy: 'xml', file_name: 'youtube.rb' } }, format: 'js'
        expect(assigns(:harvest_job)).to eq job
      end

      it 'should save the harvest job' do
        job.should_receive(:save)
        post :create, params: { harvest_job: { strategy: 'xml', file_name: 'youtube.rb' } }, format: 'js'
      end
    end

    describe '#GET show' do
      it 'finds the harvest job' do
        HarvestJob.should_receive(:find).with('1') { job }
        get :show, params: { id: 1 }, format: 'js'
        expect(assigns(:harvest_job)).to eq job
      end
    end

    describe 'PUT Update' do
      before(:each) do
        HarvestJob.stub(:find).with('1') { job }
      end

      it 'finds the harvest job' do
        HarvestJob.should_receive(:find).with('1') { job }
        put :update, params: { id: 1, harvest_job: { stop: true } }, format: 'js'
        expect(assigns(:harvest_job)).to eq job
      end

      it 'should update the attributes' do
        params = ActionController::Parameters.new(stop: 'true').permit!
        job.should_receive(:update).with(params)
        put :update, params: { id: 1, harvest_job: { stop: true } }, format: 'js'
      end
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
