require 'spec_helper'

describe Preview do

	let(:preview_attributes) { { harvest_job: {user_id: 20, environment: "preview", index: 150, parser_id: "abc123", parser_code: "code"} } }
	let(:job) { HarvestJob.new(environment: "preview", index: 1, harvest_failure: {}) }
	let(:preview) { FactoryGirl.build(:preview, id: "abc123") }

	describe ".spawn_preview_worker" do
		before do
			HarvestJob.stub(:create) { job }
			job.stub(:valid?) { true }
			Preview.stub(:create) { preview }
		end

		it "should create a preview object" do
			Preview.should_receive(:create)
		  Preview.spawn_preview_worker(preview_attributes)
		end

		it "should create a harvest job" do
		  HarvestJob.should_receive(:create).with(preview_attributes[:harvest_job]) { job }
		  Preview.spawn_preview_worker(preview_attributes)
		end

		it "should enqueue the job" do
		  Preview.spawn_preview_worker(preview_attributes)
		  expect(PreviewWorker).to have_enqueued_job(job.id.to_s, preview.id )
		end

		it "should return the preview_id" do
		  Preview.spawn_preview_worker(preview_attributes).should eq preview
		end

		context "harvest_failure" do

			let(:running_job) { HarvestJob.new(environment: "preview", index: 1, harvest_failure: {}) }

			before do
				job.stub(:valid?) { false }
				job.stub(:harvest_failure) { {} }
				Preview.stub(:find) { preview }
				preview.stub(:update_attribute)
			end

			it "should stop the currently active job" do
				HarvestJob.should_receive(:where).with(status: "active", parser_id: job.parser_id, environment: "preview") { [running_job] }
			  running_job.should_receive(:update_attribute).with(:status, "stopped")
			  Preview.spawn_preview_worker(preview_attributes)
			end
		end
	end
end