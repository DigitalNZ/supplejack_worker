# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestSchedulesController < ApplicationController

  before_action :authenticate_user!

  def index
    @harvest_schedules = if params[:harvest_schedule]
                           HarvestSchedule.where(harvest_schedule_params)
                         else
                           HarvestSchedule.all
                         end
    render json: @harvest_schedules
  end

  def next
    render json: HarvestSchedule.next
  end

  def show
    @harvest_schedule = HarvestSchedule.find(params[:id])
    render json: @harvest_schedule
  end

  def create
    @harvest_schedule = HarvestSchedule.create(harvest_schedule_params)

    if @harvest_schedule.save
      render json: @harvest_schedule
    else
      render json: { errors: @harvest_schedule.errors }, status: 422
    end
  end

  def update
    @harvest_schedule = HarvestSchedule.find(params[:id])

    @harvest_schedule.update_attributes(harvest_schedule_params)
    render json: @harvest_schedule
  end

  def destroy
    @harvest_schedule = HarvestSchedule.find(params[:id])
    @harvest_schedule.destroy
    render json: @harvest_schedule
  end

  private

  def harvest_schedule_params
    params.require(:harvest_schedule).permit!
  end
end
