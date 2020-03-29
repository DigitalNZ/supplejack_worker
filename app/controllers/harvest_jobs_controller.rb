# frozen_string_literal: true

# app/controllers/harvest_jobs_controller.rb
class HarvestJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @harvest_jobs = HarvestJob.search(harvest_job_params)

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
      params.require(:harvest_job).permit(:created_at, :updated_at, :throughput, :invalid_records_count,
                                          :posted_records_count, :last_posted_record_id, :retried_records_count,
                                          :harvest_schedule_id, :_type, :limit, :index, :mode, :strategy,
                                          :file_name, :stop, :parser_id, :version_id, :user_id, :environment,
                                          :start_time, :end_time, :records_count, :duration, :status,
                                          :status_message, :failed_records_count, :invalid_records,
                                          :harvest_failure, harvest_job: [:user_id, :parser_id, :version_id,
                                            :environment, :limit, :mode, :created_at,
                                            :end_time, :records_count, :throughput, :status,
                                            :status_message, :environment, :invalid_records_count,
                                            :failed_records_count, :type, :mode], enrichments: [])
    end
end
