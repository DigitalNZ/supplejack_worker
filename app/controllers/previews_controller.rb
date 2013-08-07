class PreviewsController < ApplicationController

	respond_to :json

	def create
		@preview = Preview.spawn_preview_worker(params[:preview])
		respond_with @preview
	end

	def show
		@preview = Preview.find(params[:id])
		respond_with @preview
	end
end