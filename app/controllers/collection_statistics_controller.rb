class CollectionStatisticsController < ApplicationController

	respond_to :json

	def index
    if params[:collection_statistics]
      @collection_statistics = CollectionStatistics.where(params[:collection_statistics])
    else
      @collection_statistics = CollectionStatistics.all
    end
    respond_with @collection_statistics
  end

end