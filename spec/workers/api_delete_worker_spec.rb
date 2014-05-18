# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

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