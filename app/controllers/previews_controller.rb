# frozen_string_literal: true

class PreviewsController < ApplicationController
  def create
    PreviewWorker.perform_async(params[:job_id], params[:preview_id])

    head :ok
  end
end
