# frozen_string_literal: true
class CollectionStatisticsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:collection_statistics]
      @collection_statistics = CollectionStatistics.where(collection_statistics_params)
    else
      @collection_statistics = CollectionStatistics.all
    end
    render json: @collection_statistics
  end

  private

  def collection_statistics_params
    params.require(:collection_statistics).permit!
  end
end
