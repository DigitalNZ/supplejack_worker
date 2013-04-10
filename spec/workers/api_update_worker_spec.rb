require "spec_helper"

describe ApiUpdateWorker do

	let(:worker) { ApiUpdateWorker.new }
	let(:job) { mock(:enrichment_job).as_null_object }

	describe "#perform" do
		before(:each) do
		  EnrichmentJob.stub(:find).with(1) {job}

		end

		it "should post attributes to the api" do
		  RestClient.should_receive(:post).with("#{ENV["API_HOST"]}/harvester/records/123/sources.json", '{"source":{}}', content_type: :json, accept: :json)
		  worker.perform(123, {}, 1)
		end

		it "should update the posted_records_count on the enrichment job" do
			RestClient.stub(:post) {}
		  job.should_receive(:inc).with(:posted_records_count, 1)
		  worker.perform(123, {}, 1)
		end
	end

end