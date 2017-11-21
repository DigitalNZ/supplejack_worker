# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestJobsController < ApplicationController

  before_action :authenticate_user!

  def index
    @harvest_jobs = HarvestJob.search(params)
    response.headers["X-total"] = @harvest_jobs.total_count.to_s
    response.headers["X-offset"] = @harvest_jobs.offset_value.to_s
    response.headers["X-limit"] = @harvest_jobs.limit_value.to_s
    render json: @harvest_jobs, serializer: ActiveModel::ArraySerializer
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