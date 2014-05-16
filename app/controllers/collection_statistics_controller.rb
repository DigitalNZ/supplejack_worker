# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

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