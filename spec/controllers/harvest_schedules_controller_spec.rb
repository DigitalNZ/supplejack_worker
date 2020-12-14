# frozen_string_literal: true

require 'rails_helper'

describe HarvestSchedulesController do
  let(:schedule) { double(:harvest_schedule, save: true, destroy: true, update: true) }

  describe 'authorized requests' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
    end


    describe 'GET index' do
      it 'returns all the harvest schedules' do
        expect(HarvestSchedule).to receive(:all).and_return([schedule])
        get :index
        expect(assigns(:harvest_schedules)).to eq [schedule]
      end

      context 'params[:harvest_schedule] is present' do
        it 'uses a where query ' do
          allow(HarvestSchedule).to receive(:where).and_return([schedule])
          expect(HarvestSchedule).to receive(:where).with('parser_id' => 'abc123')

          get :index, params: { harvest_schedule: { parser_id: 'abc123' } }
          expect(assigns(:harvest_schedules)).to eq [schedule]
        end
      end
    end

    describe 'GET show' do
      before(:each) do
        allow(HarvestSchedule).to receive(:find).with('1').and_return(schedule)
      end

      it 'finds the harvest schedule' do
        expect(HarvestSchedule).to receive(:find).with('1').and_return(schedule)
        get :show, params: { id: 1 }
        expect(assigns(:harvest_schedule)).to eq schedule
      end
    end

    describe 'POST create' do
      before(:each) do
        allow(HarvestSchedule).to receive(:new).and_return(schedule)
      end

      it 'creates a new harvest schedule' do
        params = ActionController::Parameters.new(cron: '* * * * *').permit!
        expect(HarvestSchedule).to receive(:create).with(params).and_return(schedule)
        post :create, params: { harvest_schedule: { cron: '* * * * *' } }
        expect(assigns(:harvest_schedule)).to eq schedule
      end
    end

    describe 'PUT update' do
      before(:each) do
        allow(HarvestSchedule).to receive(:find).with('1').and_return(schedule)
      end

      it 'finds the harvest schedule' do
        allow(HarvestSchedule).to receive(:find).with('1').and_return(schedule)
        put :update, params: { id: 1, harvest_schedule: { cron: '* * * * *' } }
        expect(assigns(:harvest_schedule)).to eq schedule
      end

      it 'updates the attributes' do
        params = ActionController::Parameters.new(cron: '* * * * *').permit!
        allow(schedule).to receive(:update).with(params)
        put :update, params: { id: 1, harvest_schedule: { cron: '* * * * *' } }
      end
    end

    describe 'GET destroy' do
      before(:each) do
        allow(HarvestSchedule).to receive(:find).with('1').and_return(schedule)
      end

      it 'finds the harvest schedule' do
        allow(HarvestSchedule).to receive(:find).with('1').and_return(schedule)
        delete :destroy, params: { id: 1 }
        expect(assigns(:harvest_schedule)).to eq schedule
      end

      it 'destroys the schedule' do
        expect(schedule).to receive(:destroy)
        delete :destroy, params: { id: 1 }
      end
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
