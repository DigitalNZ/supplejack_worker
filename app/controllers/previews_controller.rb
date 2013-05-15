class PreviewsController < ApplicationController

	respond_to :json

	def create
		@preview = Preview.new(params[:preview])
		render json: @preview.as_json
	end
end