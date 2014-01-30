class AbstractJobsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  def index
    @abstract_jobs = AbstractJob.search(params)
    response.headers["X-total"] = @abstract_jobs.total_count.to_s
    response.headers["X-offset"] = @abstract_jobs.offset_value.to_s
    response.headers["X-limit"] = @abstract_jobs.limit_value.to_s
    respond_with @abstract_jobs, serializer: ActiveModel::ArraySerializer
  end

  def jobs_since
    respond_with AbstractJob.jobs_since(params)
  end
end