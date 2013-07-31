require 'spec_helper'

describe PreviewsController do
	describe "POST 'create'" do

		let(:preview) { double(:preview) }

		it "should assign @preview with a new preview object" do
		  Preview.should_receive(:new).with({"parser_code" => "CODE", "index" => "1000"}) { "{\"record\":\"rec\"}" }
		  post :create, preview: {parser_code: "CODE", index: 1000}
		  assigns(:preview).should eq "{\"record\":\"rec\"}"
		end
	end
end