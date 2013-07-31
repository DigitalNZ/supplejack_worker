require "spec_helper"

describe ApiDeleteWorker do

	let(:worker) { ApiDeleteWorker.new }

	before do
	 RestClient.stub(:delete)
	 AbstractJob.stub(:find) { double(:job).as_null_object }
	end

	describe "#perform" do
		it "should send a put request to the api with the internal identifier" do
			RestClient.should_receive(:put).with("#{ENV["API_HOST"]}/harvester/records/delete", {id: 'abc123'}, {content_type: :json, accept: :json})
		  worker.perform("abc123", "r3ec343")
		end
	end
end