# frozen_string_literal: true

# app/controllers/abstract_jobs_controller.rb
class AbstractJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @abstract_jobs = AbstractJob.search(search_params)

    headers = ['X-total', 'X-offset', 'X-limit']
    values = %i[total_count offset_value limit_value]

    headers.zip(values) do |header, value|
      response.headers[header] = @abstract_jobs.send(value).to_s
    end

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
