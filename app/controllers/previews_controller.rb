# frozen_string_literal: true

class PreviewsController < ApplicationController
  def create
    PreviewStartJob.perform_later(params[:preview][:id])

    head :ok
  end
end
