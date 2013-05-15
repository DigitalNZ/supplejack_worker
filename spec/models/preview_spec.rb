require 'spec_helper'

describe Preview do
	let(:preview) { klass.new(user_id: 20, environment: "preview", index: 150, parser_id: "abc123", parser_code: "code") }

	let(:klass) { Preview }

	describe "#initialize" do
		it "should initialize parser_code" do
		  preview = klass.new(parser_code: "code")
		  preview.parser_code.should eq "code"
		end

		it "should initialize index" do
		  preview = klass.new(index: 1000)
		  preview.index.should eq 1000
		end

		it "should default index to 0" do
		  preview = klass.new
		  preview.index.should eq 0
		end

		it "environment should be set to 'staging'" do
		  preview = klass.new
		  preview.environment.should eq "staging"
		end

		it "should initialize parser_id" do
		  preview = klass.new(parser_id: "xyhen123")
		  preview.parser_id.should eq "xyhen123"
		end

		it "should initialize the user_id" do
		  preview = klass.new(user_id: "xyz123")
		  preview.user_id.should eq "xyz123"
		end
	end

	describe "#as_json" do
		let(:record) { mock(:record, attributes: {}) }
		let(:harvest_record) {mock(:record, attributes: {}, raw_data: "raw_data")}
		let(:harvest_job) {mock(:harvest_job, id: 123)}

		before do
			preview.instance_variable_set(:@record, record)
			preview.instance_variable_set(:@last_processed_record, harvest_record)
			preview.instance_variable_set(:@harvest_job, harvest_job)
			preview.stub(:validation_errors) {}
			preview.stub(:field_errors) {}
			harvest_job.stub(:harvest_failure) {}
			preview.stub(:process_record) {}
		end

		it "calls process_record" do
			preview.should_receive(:process_record)
			preview.as_json
		end

		it "should return a hash with the records attributes" do
		  preview.as_json.should include(record: {})
		end

		it "should return a hash with the raw data" do
		  preview.as_json.should include(raw_data: "raw_data")
		end

		it "should return a hash with the harvest job id" do
		  preview.as_json.should include(harvest_job_id: 123)
		end

		it "should return a hash with the validation_errors" do
			preview.stub(:validation_errors) { [{title: "titles"}] }
		  preview.as_json[:errors][:validation_errors].should include({title: "titles"})
		end

		it "should return a hash with the field_errors" do
			preview.stub(:field_errors) { [{title: "titles"}] }
		  preview.as_json[:errors][:field_errors].should include({title: "titles"})
		end
	end

	describe "#validation_errors" do
		let(:record) { mock(:record) }

		it "returns the validation errors" do
			preview.instance_variable_set(:@last_processed_record, record)
		  record.stub(:errors) { {title: "WRONG!"} }
		  preview.send(:validation_errors).should eq([{title: "WRONG!"}])
		end

		it "returns an empty hash if there is no @last_processed_record " do
		  preview.send(:validation_errors).should eq({})
		end
	end

	describe "#field_errors" do
		let(:record) { mock(:record) }

		it "returns the validation errors" do
			preview.instance_variable_set(:@last_processed_record, record)
		  record.stub(:field_errors) { {title: "WRONG!"} }
		  preview.send(:field_errors).should eq({title: "WRONG!"})
		end

		it "returns an empty hash if there is no @last_processed_record " do
		  preview.send(:field_errors).should eq({})
		end
	end

	describe "#strip_ids" do
	  it "strips the _id's from all documents in record" do
	    result = preview.send(:strip_ids, {
	    	'_id' => '123', 
	    	'blah' => 'blah', 
	    	'sources' => {
	    		'_id' => '12',
	    		'authorities' => [{'_id' => 'ab12'}, 'blah'],
	    	}})
	    result.should_not include('_id' => '123')
	    result['sources'].should_not include('_id' => '12')
	    result['sources']['authorities'][0].should_not include('_id' => 'ab12')
	    result.should include('blah' => 'blah')
	  end

	  it "returns nil if nil is passed" do
	    preview.send(:strip_ids, nil).should eq nil
	  end
	end

	describe "#process_record" do
		let(:record) { mock(:record) }
		let(:preview) { klass.new(user_id: 20, environment: "preview", index: 150, parser_id: "abc123", parser_code: "code") }
		let(:harvest_job) { FactoryGirl.create(:harvest_job) }
		let(:harvest_worker) { mock(:harvest_worker, last_processed_record: record ).as_null_object }
		let(:enrichment_job) { FactoryGirl.create(:enrichment_job) }
		let(:enrichment_worker) { mock(:enrichment_worker) }

		before do
			HarvestJob.stub(:create) { harvest_job }
			harvest_job.stub_chain(:parser, :enrichment_definitions).and_return([["ndha_attachments", {}], ["tapuhi_groups", {type:"TapGroup"}]])
			EnrichmentWorker.any_instance.stub(:perform)
			HarvestWorker.any_instance.stub(:perform)
			HarvestWorker.stub(:new) { harvest_worker }
			harvest_job.stub(:harvest_failure?) { false }
			record.stub(:valid?) { true }
		end

		it "should run a harvest job with the defined index" do
		  HarvestJob.should_receive(:create).with(user_id: 20, environment: "preview", index: 150, limit: 151, parser_id: "abc123", parser_code: "code") { harvest_job }
		  HarvestWorker.should_receive(:new) { harvest_worker }
		  harvest_worker.should_receive(:perform).with(harvest_job.id)
		  preview.send(:process_record)
		end

		it "should run enrichments that don't have types" do
			harvest_job.stub(:last_posted_record_id) { 123 }
		  
		  EnrichmentJob.should_receive(:create_from_harvest_job).with(harvest_job, "ndha_attachments") { enrichment_job }
		  enrichment_job.should_receive(:update_attribute).with(:record_id, 123)
		  EnrichmentWorker.should_receive(:new) { enrichment_worker }
		  enrichment_worker.should_receive(:perform).with(enrichment_job.id)
		  preview.send(:process_record)
		end

		it "should retrieve the record from mongo" do
			harvest_job.stub(:last_posted_record_id) { "123" }
		  Repository::PreviewRecord.should_receive(:where).with(record_id: 123).and_call_original
		  preview.send(:process_record)
		end

		context "failures" do

			let(:record) { mock(:record) }

			after do
				EnrichmentJob.should_not_receive(:create_from_harvest_job)
				preview.send(:process_record)
			end

			it "should not enrich the record if the harvest failed" do
				harvest_job.stub(:harvest_failure?) { true }
			end

			it "should not enrich an invalid record" do
			  HarvestWorker.any_instance.stub(:last_processed_record) { record }
			  record.stub(:valid?) { false }
			end
		end

		context "enrichments with type set" do

			before { harvest_job.stub_chain(:parser, :enrichment_definitions).and_return([["tapuhi_groups", {type:"TapGroup"}]]) }

			it "should not run enrichments that do have types" do
			  EnrichmentJob.should_not_receive(:create_from_harvest_job).with(harvest_job, "tapuhi_groups") { enrichment_job }
			  preview.send(:process_record)
			end
		end
	end

end