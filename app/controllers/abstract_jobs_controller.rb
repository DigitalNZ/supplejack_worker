# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class AbstractJobsController < ApplicationController
  before_action :authenticate_user!

  def index
    @abstract_jobs = AbstractJob.search(params)
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
