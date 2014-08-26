# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class LinkCheckJobsController < ApplicationController

  def create
    @link_check = LinkCheckJob.create(link_check_params)
    render json: @link_check
  end

  private

  def link_check_params
    params.require(:link_check).permit(:url, :record_id, :source_id)
  end
end
