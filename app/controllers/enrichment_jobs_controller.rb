# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class EnrichmentJobsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  def show
    @enrichment_job = EnrichmentJob.find(params[:id])
    respond_with @enrichment_job
  end

  def create
    @enrichment_job = EnrichmentJob.new(params[:enrichment_job])
    if @enrichment_job.save
      respond_with @enrichment_job
    else
      render json: {errors: @enrichment_job.errors }, status: 422
    end
  end

  def update
    @enrichment_job = EnrichmentJob.find(params[:id])
    @enrichment_job.update_attributes(params[:enrichment_job])
    respond_with @enrichment_job
  end
end