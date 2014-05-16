# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

describe PreviewsController do

	let(:preview) { mock_model(Preview, id: "123").as_null_object }
	let(:user) { mock_model(User, id: "1234").as_null_object }
	
	describe "POST 'create'" do

		let(:preview) { double(:preview) }

		before { Preview.stub(:spawn_preview_worker) { "abc123" } }

		it "spawns a preview worker" do
		  Preview.should_receive(:spawn_preview_worker).with("id" => "123", "harvest_job" => {"parser_code" => "CODE", "index" => "1000"})
		  post :create, preview: { id: "123", harvest_job: {parser_code: "CODE", index: 1000} }
		end
	end

	describe "GET show" do
		it "should find the preview object" do
		  Preview.should_receive(:find).with(preview.id.to_s) { preview }
		  get :show, id: preview.id
		  assigns(:preview).should eq preview
		end
	end
end