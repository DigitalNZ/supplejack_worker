# frozen_string_literal: true

# app/controllers/abstract_jobs_controller.rb
class AbstractJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @abstract_jobs = AbstractJob.search(search_params)
    response.headers['X-total'] = @abstract_jobs.total_count.to_s
    response.headers['X-offset'] = @abstract_jobs.offset_value.to_s
    response.headers['X-limit'] = @abstract_jobs.limit_value.to_s
    render json: @abstract_jobs
  end

  def jobs_since
    render json: AbstractJob.jobs_since(search_params)
  end

  private

  def search_params
    params.permit(:status, :environment, :parser_id, :datetime, :page)
  end
end
