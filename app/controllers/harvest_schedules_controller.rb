class HarvestSchedulesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  def index
    if params[:harvest_schedule]
      @harvest_schedules = HarvestSchedule.where(params[:harvest_schedule])
    else
      @harvest_schedules = HarvestSchedule.all
    end
    respond_with @harvest_schedules, serializer: ActiveModel::ArraySerializer
  end

  def show
    @harvest_schedule = HarvestSchedule.find(params[:id])
    respond_with @harvest_schedule
  end

  def create
    @harvest_schedule = HarvestSchedule.create(params[:harvest_schedule])

    if @harvest_schedule.save
      respond_with @harvest_schedule
    else
      render json: {errors: @harvest_schedule.errors }, status: 422
    end
  end

  def update
    @harvest_schedule = HarvestSchedule.find(params[:id])
    @harvest_schedule.update_attributes(params[:harvest_schedule])
    respond_with @harvest_schedule
  end

  def destroy
    @harvest_schedule = HarvestSchedule.find(params[:id])
    @harvest_schedule.destroy
    respond_with @harvest_schedule
  end
end