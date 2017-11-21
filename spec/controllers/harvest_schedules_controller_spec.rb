# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe HarvestSchedulesController do
  let(:schedule) { double(:harvest_schedule, save: true, destroy: true, update_attributes: true) }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
  end

  describe 'GET index' do
    it 'should return all the harvest schedules' do
      HarvestSchedule.should_receive(:all) { [schedule] }
      get :index
      expect(assigns(:harvest_schedules)).to eq [schedule]
    end

    context 'params[:harvest_schedule] is present' do
      it 'should use a where query ' do
        HarvestSchedule.stub(:where) { [schedule] }
        HarvestSchedule.should_receive(:where).with('parser_id' => 'abc123')
        get :index, params: { harvest_schedule: { parser_id: 'abc123' } }
        expect(assigns(:harvest_schedules)).to eq [schedule]
      end

  describe 'GET show' do
    before(:each) do
      HarvestSchedule.stub(:find).with('1') { schedule }
    end

    it 'finds the harvest schedule' do
      HarvestSchedule.should_receive(:find).with('1') { schedule }
      get :show, params: { id: 1 }
      expect(assigns(:harvest_schedule)).to eq schedule
    end
  end

  describe 'POST create' do
    before(:each) do
      HarvestSchedule.stub(:new) { schedule }
    end

    it 'creates a new harvest schedule' do
      params = ActionController::Parameters.new(cron: '* * * * *').permit!
      HarvestSchedule.should_receive(:create).with(params) { schedule }
      post :create, params: { harvest_schedule: {cron: '* * * * *'} }
      expect(assigns(:harvest_schedule)).to eq schedule
    end
  end

  describe 'PUT update' do
    before(:each) do
      HarvestSchedule.stub(:find).with('1') { schedule }
    end

    it 'finds the harvest schedule' do
      HarvestSchedule.should_receive(:find).with('1') { schedule }
      put :update, params: { id: 1 , harvest_schedule: {cron: '* * * * *'}}
      expect(assigns(:harvest_schedule)).to eq schedule
    end

    it 'should update the attributes' do
      params = ActionController::Parameters.new(cron: '* * * * *').permit!
      schedule.should_receive(:update_attributes).with(params)
      put :update, params: { id: 1 , harvest_schedule: {cron: '* * * * *'}}
    end
  end

  describe 'GET destroy' do
    before(:each) do
      HarvestSchedule.stub(:find).with('1') { schedule }
    end

    it 'finds the harvest schedule' do
      HarvestSchedule.should_receive(:find).with('1') { schedule }
      delete :destroy, params: { id: 1 }
      expect(assigns(:harvest_schedule)).to eq schedule
    end

    it 'should destroy the schedule' do
      schedule.should_receive(:destroy)
      delete :destroy, params: { id: 1 }
    end
  end
end
