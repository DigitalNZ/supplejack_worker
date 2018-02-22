# frozen_string_literal: true
class HarvestJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @harvest_jobs = HarvestJob.search(params.permit!)
    response.headers['X-total'] = @harvest_jobs.total_count.to_s
    response.headers['X-offset'] = @harvest_jobs.offset_value.to_s
    response.headers['X-limit'] = @harvest_jobs.limit_value.to_s
    render json: @harvest_jobs
  end

  def show
    @harvest_job = HarvestJob.find(params[:id])
    render json: @harvest_job
  end

  def create
    @harvest_job = HarvestJob.new(harvest_job_params)

    if @harvest_job.save
      render json: @harvest_job
    else
      render json: { errors: @harvest_job.errors }, status: 422
    end
  end

  def update
    @harvest_job = HarvestJob.find(params[:id])
    @harvest_job.update_attributes(harvest_job_params)
    render json: @harvest_job
  end

  private

  def harvest_job_params
    params.require(:harvest_job).permit!
  end
end
