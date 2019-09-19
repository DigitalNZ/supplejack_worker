# frozen_string_literal: true

# app/controllers/previews_controller.rb
class PreviewsController < ApplicationController
  def create
    @preview = Preview.spawn_preview_worker(preview_params)
    render json: @preview
  end

  def show
    @preview = Preview.find(params[:id])
    render json: @preview
  end

  private

  def preview_params
    params.require(:preview).permit!
  end
end
