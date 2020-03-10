# frozen_string_literal: true

# app/controllers/harvest_jobs_controller.rb
class HarvestJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @harvest_jobs = HarvestJob.search(params.permit!)

    headers = ['X-total', 'X-offset', 'X-limit']
    values = %i[total_count offset_value limit_value]

    headers.zip(values) do |header, value|
      response.headers[header] = @harvest_job.send(value).to_s
    end

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
    @harvest_job.update(harvest_job_params)
    render json: @harvest_job
  end

  private
    def harvest_job_params
      params.require(:harvest_job).permit!
    end
end
