# frozen_string_literal: true

# app/controllers/abstract_jobs_controller.rb
class AbstractJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @abstract_jobs = AbstractJob.search(search_params)

    header_values = {
      'X-total' => :total_count,
      'X-offset' => :offset_value,
      'X-limit' => :limit_value
    }

    header_values.each do |header, value|
      response.headers[header] = @abstract_jobs.send(value).to_s
    end


    render json: @abstract_jobs
  end

  # def jobs_since
  #   render json: AbstractJob.jobs_since(search_params)
  # end

  private
    def search_params
      params.permit(:status, :environment, :parser_id, :datetime, :page)
    end
end
