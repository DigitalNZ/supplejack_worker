# frozen_string_literal: true

# app/controllers/link_check_jobs_controller.rb
class LinkCheckJobsController < ApplicationController
  before_action :authenticate_user!

  def create
    @job = LinkCheckJob.new(link_check_params)

    if @job.valid?
      @job.save!

      render json: @job
    else
      render json: { errors: @job.errors.full_messages }, status: :bad_request
    end
  end

  private
    def link_check_params
      params.require(:link_check).permit(:url, :source_id, :record_id)
    end
end
