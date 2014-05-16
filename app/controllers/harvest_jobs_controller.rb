# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestJobsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  def index
    @harvest_jobs = HarvestJob.search(params)
    response.headers["X-total"] = @harvest_jobs.total_count.to_s
    response.headers["X-offset"] = @harvest_jobs.offset_value.to_s
    response.headers["X-limit"] = @harvest_jobs.limit_value.to_s
    respond_with @harvest_jobs, serializer: ActiveModel::ArraySerializer
  end

  def show
    @harvest_job = HarvestJob.find(params[:id])
    respond_with @harvest_job
  end

  def create
    @harvest_job = HarvestJob.new(params[:harvest_job])
    if @harvest_job.save
      respond_with @harvest_job
    else
      render json: {errors: @harvest_job.errors }, status: 422
    end
  end

  def update
    @harvest_job = HarvestJob.find(params[:id])
    @harvest_job.update_attributes(params[:harvest_job])
    respond_with @harvest_job
  end
end