# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

describe ApiUpdateWorker do

	let(:worker) { ApiUpdateWorker.new }
	let(:job) { FactoryGirl.create(:harvest_job) }

	describe "#perform" do
		let(:response) { {record_id: 123}.to_json }
		before(:each) do
		  AbstractJob.stub(:find).with(1) {job}
		  RestClient::Request.stub(:execute) { response }
		end

		it "should post attributes to the api" do
		  RestClient::Request.should_receive(:execute).with({:method=>:post, :url=>"#{ENV["API_HOST"]}/harvester/records/123/fragments.json", :payload=>"{}", :timeout=>10, :open_timeout=>10, :headers=>{:content_type=>:json, :accept=>:json}}) { response }
		  worker.perform("/harvester/records/123/fragments.json", {}, 1)
	end

		it "should set the jobs last_posted_record_id" do
			job.should_receive(:set).with({last_posted_record_id: 123})
		  RestClient::Request.should_receive(:execute) { response }
		  worker.perform("/harvester/records/123/fragments.json", {}, 1)
		end

		it "should update the posted_records_count on the job" do
		  job.should_receive(:inc).with({ posted_records_count: 1})
		  worker.perform(123, {}, 1)
		end

		it "merges preview=true into attributes if environment is preview" do
			job.stub(:environment) { "preview" }
			RestClient::Request.should_receive(:execute).with({:method=>:post, :url=>"#{ENV["API_HOST"]}/harvester/records/123/fragments.json", :payload=>"{\"preview\":true}", :timeout=>10, :open_timeout=>10, :headers=>{:content_type=>:json, :accept=>:json}}) { response }
			worker.perform("/harvester/records/123/fragments.json", {}, 1)
		end
	end
end
