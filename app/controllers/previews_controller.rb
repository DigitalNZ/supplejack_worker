# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

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
