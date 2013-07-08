class LinkCheckJobsController < ApplicationController

  respond_to :json

  def create
    @link_check = LinkCheckJob.create(link_check_params)
    respond_with @link_check
  end

  private

  def link_check_params
    params.require(:link_check).permit(:url, :record_id)
  end
end
