require "spec_helper"

describe PreviewWorker do

	let(:job) { HarvestJob.new(environment: "preview", index: 3, harvest_failure: {}, last_posted_record_id: 1234) }
	let(:preview) { mock_model(Preview, _id: "123").as_null_object }

	let(:worker) { PreviewWorker.new }

	let(:record1) { double(:record, raw_data: '{"id": "123"}', attributes: {title: "Clip the dog"}, field_errors: {}, validation_errors: {}) }
	let(:record2) { double(:record) }

	before do
		worker.stub(:job) { job }
		job.stub(:records).and_yield(record1, 0).and_yield(record2, 1).and_yield(record1, 2).and_yield(record2, 3)
		record1.stub(:valid?) { true }
		record2.stub(:valid?) { true }
		worker.stub(:preview) { preview }
		preview.stub(:update_attribute)
		worker.stub(:current_record_id) { 1234 }
	end

	describe "#perform" do

		before do
			worker.stub(:preview) { preview }
			worker.stub(:process_record)
			worker.stub(:enrich_record)
		end

		it "sets @job_id to the harvest_job_id" do
		  worker.perform("abc123", "preview123")
		  worker.job_id.should eq "abc123"
		end

		it "sets @job_id" do
		  worker.perform({"$oid" => "abc123"}, "preview123")
		  worker.job_id.should eq "abc123"
		end

		it "iterates through each of the jobs records" do
			job.should_receive(:records).and_yield(record1, 0).and_yield(record1, 1)
		  worker.perform("abc123", "preview123")
		end

		it "should only process 1 record that is at the given index" do
		  worker.should_receive(:process_record).with(record2)
		  worker.perform("abc123", "preview123")
		end

		it "should only process 1 record that is at the given index" do
		  worker.should_receive(:process_record).once
		  worker.perform("abc123", "preview123")
		end

		it "should enrich the record" do
			worker.should_receive(:enrich_record).once
		  worker.perform("abc123", "preview123")
		end

		context "harvest_failure" do

			before { job.stub(:harvest_failure) { '{"error":"message"}' } }

			it "should update the preview object with validation errors" do
			  preview.should_receive(:update_attribute).with(:harvest_failure, job.harvest_failure.to_json)
			  worker.perform("abc123", "preview123")
			end
		end
	end

	describe "#strip_ids" do
    it "strips the _id's from all documents in record" do
      result = worker.send(:strip_ids, {
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
      worker.send(:strip_ids, nil).should eq nil
    end
  end

	describe "#preview" do

		before do
		  worker.unstub(:preview)
		  worker.instance_variable_set(:@preview_id, "123")
		end

		it "should find the preview object" do
		  Preview.should_receive(:find).with("123") { preview }
		  worker.send(:preview)
		end

		it "should memoize the find" do
			Preview.should_receive(:find).with("123").once { preview }
		  worker.send(:preview)
		  worker.send(:preview)
		end
	end

	describe "#process_record" do

		before do
		 worker.stub(:preview) { preview }
		 record1.stub(:deletable?) { false }
		 record1.stub(:errors) { {} }
		 preview.stub(:save)
		end

		it "should update the attribute status to: 'harvesting record'" do
		  preview.should_receive(:update_attribute).with(:status, 'Parser loaded and data fetched. Parsing raw data and checking harvest validations...')
		  worker.send(:process_record, record1)
		end

		it "should update the preview object with the raw data" do
		  preview.should_receive(:raw_data=).with(record1.raw_data)
		  worker.send(:process_record, record1)
		end

		it "should update the preview object with the harvested_attributes" do
			preview.should_receive(:harvested_attributes=).with(record1.attributes.to_json)
		  worker.send(:process_record, record1)
		end

		it "should update the preview object with whether it is deletable or not" do
		  preview.should_receive(:deletable=).with(false)
		  worker.send(:process_record, record1)
		end

		it "should update the preview object with field errors" do
		  preview.should_receive(:field_errors=).with(record1.field_errors.to_json)
		  worker.send(:process_record, record1)
		end

		context "validation errors" do

			before { record1.stub(:valid?) { false } }

			it "should update the preview object with validation errors" do
			  preview.should_receive(:validation_errors=).with([].to_json)
			  worker.send(:process_record, record1)
			end
		end

		it "should save the preview object" do
		  preview.should_receive(:save)
		  worker.send(:process_record, record1)
		end
	end

	describe "#current_record_id" do
		before { worker.unstub(:current_record_id) }
		it "should reload the job and return the last last_posted_record_id" do
		  job.should_receive(:reload) { job }
		  worker.send(:current_record_id).should eq "1234"
		end
	end

	describe "#enrich_record" do

		let(:record) { double(:record, attributes: {title: "Hello"}) }

		before do
			record1.stub(:valid?) { true }
			record1.stub(:deletable?) { false }
			job.stub_chain(:parser, :enrichment_definitions) { {} }
			Repository::PreviewRecord.stub(:where) { [record] }
			worker.stub(:strip_ids) { record.attributes }
			worker.stub(:post_to_api)
		end

		context "record not valid" do

			before { record1.stub(:valid?) { false } }

			it "should not post to API if the record is not valid" do
			  worker.should_not_receive(:post_to_api)
			  worker.send(:enrich_record, record1)
			end
		end

		context "record is a deletion" do

			before { record1.stub(:deletable?) { true } }

			it "should not post to API if the record is not valid" do
			  worker.should_not_receive(:post_to_api)
			  worker.send(:enrich_record, record1)
			end
		end

		it "should post the record to the API" do
		  worker.should_receive(:post_to_api).with(record1.attributes, false)
		  worker.send(:enrich_record, record1)
		end

		context "enrichments defined" do

			let(:enrichment_job) { EnrichmentJob.new }
			let(:enrichment_worker) { double(:enrichment_worker) }

			before do
				job.stub_chain(:parser, :enrichment_definitions).and_return({ndha: { }})
				EnrichmentJob.stub(:create_from_harvest_job) { enrichment_job }
				EnrichmentWorker.any_instance.stub(:perform)
			end

			it "should create a enrichment job" do
			  EnrichmentJob.should_receive(:create_from_harvest_job).with(job, :ndha)
			  worker.send(:enrich_record, record1)
			end

			it "should update the enrichment jobs record_id using current_record_id" do
				worker.send(:enrich_record, record1)
			  enrichment_job.record_id.should eq 1234
			end

			it "should enqueue a job for the EnrichmentWorker" do
				EnrichmentWorker.should_receive(:new) { enrichment_worker }
				enrichment_worker.should_receive(:perform).with(enrichment_job.id)
			  worker.send(:enrich_record, record1)
			end
		end

		it "should find the preview record" do
		  Repository::PreviewRecord.should_receive(:where).with(record_id: 1234) { [record] }
		  worker.send(:enrich_record, record1)
		end

		it "should set the previews api_record" do
		  preview.should_receive(:update_attribute).with(:api_record, record.attributes.to_json)
		  worker.send(:enrich_record, record1)
		end

		context "enrichments with type set" do
			before { job.stub_chain(:parser, :enrichment_definitions).and_return({tapuhi_groups: { type: "tapuhi_groups"}}) }
 
			it "should not run enrichments that do have types" do
			  EnrichmentJob.should_not_receive(:create_from_harvest_job).with(job, :tapuhi_groups) { enrichment_job }
			  worker.send(:enrich_record, record1)
			end
		end
	end

	describe "#validation_errors" do
		let(:record) { double(:record) }

		it "returns the validation errors" do
		  record.stub(:errors) { {title: "WRONG!"} }
		  worker.send(:validation_errors, record).should eq([{title: "WRONG!"}])
		end

		it "returns an empty hash if there is no @last_processed_record " do
			record.stub(:errors) { {} }
		  worker.send(:validation_errors, record).should be_empty
		end
	end
end