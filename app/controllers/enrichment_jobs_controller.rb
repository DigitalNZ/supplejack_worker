# frozen_string_literal: true

# app/controllers/enrichment_jobs_controller.rb
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
    @enrichment_job.update(enrichment_job_params)
    respond_with @enrichment_job
  end

  private
    def enrichment_job_params
      params.require(:enrichment_job).permit(:enrichment, :record_id, :strategy, :stop, :file_name, :parser_id,
                                             :version_id, :user_id, :environment, :start_time, :end_time, :records_count,
                                             :throughput, :created_at, :updated_at, :duration, :status, :status_message,
                                             :user_id, :parser_id, :version_id, :posted_records_count, :processed_count,
                                             :record_id, :last_posted_record_id,
                                             enrichment_job: [:user_id, :parser_id, :version_id, :environment, :enrichment, :record_id])
    end
end
