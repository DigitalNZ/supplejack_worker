# frozen_string_literal: true
class EnrichmentJobsController < ApplicationController
  before_action :authenticate_user!

  respond_to :json

  def show
    @enrichment_job = EnrichmentJob.find(params[:id])
    respond_with @enrichment_job
  end

  def create
    @enrichment_job = EnrichmentJob.new(enrichment_job_params)
    if @enrichment_job.save
      respond_with @enrichment_job
    else
      render json: { errors: @enrichment_job.errors }, status: 422
    end
  end

  def update
    @enrichment_job = EnrichmentJob.find(params[:id])
    @enrichment_job.update_attributes(enrichment_job_params)
    respond_with @enrichment_job
  end

  private

  def enrichment_job_params
    params.require(:enrichment_job).permit!
  end
end
