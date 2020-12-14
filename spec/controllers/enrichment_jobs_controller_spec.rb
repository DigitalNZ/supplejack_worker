# frozen_string_literal: true

require 'rails_helper'

describe EnrichmentJobsController do
  let(:job) { double(:enrichment_job, save: true, update: true) }

  describe 'authorized requests' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
    end

    describe 'POST create' do
      it 'initializes a new enrichment job' do
        post :create, params: { enrichment_job: { strategy: 'xml', file_name: 'youtube.rb' }, format: 'json' }
        expect(assigns(:enrichment_job)).to be_a_new(EnrichmentJob)
        expect(assigns(:enrichment_job).strategy).to eq 'xml'
        expect(assigns(:enrichment_job).file_name).to eq 'youtube.rb'
      end

      it 'should save the enrichment job' do
        allow_any_instance_of(EnrichmentJob).to receive(:save)
        post :create, params: { enrichment_job: { strategy: 'xml', file_name: 'youtube.rb' }, format: 'json' }
        expect(assigns(:enrichment_job).strategy).to eq 'xml'
        expect(assigns(:enrichment_job).file_name).to eq 'youtube.rb'
      end
    end

    describe '#GET show' do
      it 'finds the enrichment job' do
        expect(EnrichmentJob).to receive(:find).with('1').and_return(job)
        get :show, params: { id: 1 }, format: 'json'
        expect(assigns(:enrichment_job)).to eq job
      end
    end

    describe 'PUT Update' do
      before(:each) do
        allow(EnrichmentJob).to receive(:find).with('1').and_return(job)
      end

      it 'finds the enrichment job' do
        allow(EnrichmentJob).to receive(:find).with('1').and_return(job)
        put :update, params: { id: 1, enrichment_job: { stop: true } }, format: 'json'
        expect(assigns(:enrichment_job)).to eq job
      end

      it 'should update the attributes' do
        params = ActionController::Parameters.new(stop: 'true').permit!
        expect(job).to receive(:update).with(params)
        put :update, params: { id: 1, enrichment_job: { stop: true } }, format: 'json'
      end
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :show, params: { id: 1 }, format: 'json'
    expect(response.status).to eq(401)
  end
end
