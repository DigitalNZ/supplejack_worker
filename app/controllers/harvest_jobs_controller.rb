class HarvestJobsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  def show
    @harvest_job = HarvestJob.find(params[:id])
    respond_with @harvest_job
  end

  def create
    @harvest_job = HarvestJob.new(params[:harvest_job])
    @harvest_job.save
    respond_with @harvest_job
  end

  def update
    @harvest_job = HarvestJob.find(params[:id])
    @harvest_job.update_attributes(params[:harvest_job])
    respond_with @harvest_job
  end
end