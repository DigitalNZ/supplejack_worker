# frozen_string_literal: true

# app/controllers/collection_statistics_controller.rb
class CollectionStatisticsController < ApplicationController
  before_action :authenticate_user!

  def index
    @collection_statistics = if params[:collection_statistics]
      CollectionStatistics.where(c_s_params.to_h)
    else
      CollectionStatistics.all
    end
    render json: @collection_statistics
  end

  private
    def c_s_params
      params.require(:collection_statistics).permit(:source_id, :day, :suppressed_count,
                                                    :deleted_count, :activated_count, :suppressed_records,
                                                    :deleted_records, :activated_records)
    end
end
