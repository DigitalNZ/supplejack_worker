# frozen_string_literal: true
class LinkCheckJobsController < ApplicationController
  def create
    @link_check = LinkCheckJob.create!(link_check_params)
    render json: @link_check
  end

  private

  def link_check_params
    params.require(:link_check).permit(:url, :source_id, :record_id)
  end
end
