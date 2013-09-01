require "spec_helper"

describe ApiUpdateWorker do

	let(:worker) { ApiUpdateWorker.new }
	let(:job) { double(:enrichment_job).as_null_object }

	describe "#perform" do
		let(:response) { {record_id: 123}.to_json }
		before(:each) do
		  AbstractJob.stub(:find).with(1) {job}
		  RestClient.stub(:post) { response }
		end

		it "should post attributes to the api" do
		  RestClient.should_receive(:post).with("#{ENV["API_HOST"]}/harvester/records/123/fragments.json", "{}", content_type: :json, accept: :json) { response }
		  worker.perform("/harvester/records/123/fragments.json", {}, 1)
		end

		it "should set the jobs last_posted_record_id" do
			job.should_receive(:set).with(:last_posted_record_id, 123)
		  RestClient.should_receive(:post) { response }
		  worker.perform("/harvester/records/123/fragments.json", {}, 1)
		end

		it "should update the posted_records_count on the job" do
		  job.should_receive(:inc).with(:posted_records_count, 1)
		  worker.perform(123, {}, 1)
		end

		it "merges preview=true into attributes if environment is preview" do
			job.stub(:environment) { "preview" }
			RestClient.should_receive(:post).with(anything, "{\"preview\":true}", anything) { response }
			worker.perform("/harvester/records/123/fragments.json", {}, 1)
		end
	end
end