require "spec_helper"

describe ApiDeleteWorker do

	let(:worker) { ApiDeleteWorker.new }

	before { RestClient.stub(:delete) }

	describe "#perform" do
		it "should send a put request to the api with the internal identifier" do
			RestClient.should_receive(:delete).with("#{ENV["API_HOST"]}/harvester/records/abc123", {content_type: :json, accept: :json})
		  worker.perform("abc123")
		end
	end
end