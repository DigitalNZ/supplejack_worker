# frozen_string_literal: true

# app/controllers/collection_statistics_controller.rb
class CollectionStatisticsController < ApplicationController
  before_action :authenticate_user!

  def index
    @collection_statistics = if params[:collection_statistics]
                               CollectionStatistics.where(c_s_params)
                             else
                               CollectionStatistics.all
                             end
    render json: @collection_statistics
  end

  private

  def c_s_params
    params.require(:collection_statistics).permit!
  end
end
