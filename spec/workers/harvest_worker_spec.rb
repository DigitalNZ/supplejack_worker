require "spec_helper"

describe HarvestWorker do
  let(:worker) { HarvestWorker.new }
  let(:parser) { Parser.new(strategy: "xml", name: "Natlib Pages", content: "class NatlibPages < HarvesterCore::Xml::Base; end", file_name: "natlib_pages.rb") }
  let(:job) { HarvestJob.new(environment: nil) }

  before(:each) do
    HarvesterCore.parser_base_path = Rails.root.to_s + "/tmp/parsers"
    RestClient.stub(:post)

    worker.stub(:job) { job }
    parser.load_file
  end
  
  describe "#perform" do
    let(:record) { mock(:record, attributes: {}, valid?: true) }

    before(:each) do
      job.stub(:parser) { parser }
      LoadedParser::NatlibPages.stub(:records) { [record] }
      record.stub(:deletable?) { false }
      worker.stub(:stop_harvest?) { false }
      worker.stub(:api_update_finished?) { true }
      worker.stub(:post_to_api)
    end

    context "index is defined" do
      before { LoadedParser::NatlibPages.stub(:records) { [mock(:record), mock(:record),mock(:record), record] } }
      
      it "only processes the record at position == index" do
        job.index = 3
        worker.should_receive(:process_record).once.with(record, job)
        worker.perform(1)
      end
    end

    it "starts the harvest job" do
      job.should_receive(:start!)
      worker.perform(1)
    end

    it "gets records from parser class" do
      LoadedParser::NatlibPages.should_receive(:records)
      worker.perform(1)
    end

    it "sets the proper environment from the harvest job" do
      job.stub(:environment) { "staging" }
      LoadedParser::NatlibPages.should_receive("environment=").with("staging")
      worker.perform(1)
    end

    it "processes each record" do
      worker.should_receive(:process_record).with(record, job)
      worker.perform(1)
    end

    it "records the end time" do
      worker.perform(1)
      job.end_time.should_not be_nil
    end

    it "rescues exceptions from the whole harvest and stores it" do
      LoadedParser::NatlibPages.stub(:records).and_raise "Everything broke"
      worker.perform(1)
      job.harvest_failure.message.should eq "Everything broke"
    end

    it "enqueues enrichment jobs" do
      job.should_receive(:enqueue_enrichment_jobs)
      worker.perform(1)
    end
  end

  describe "#process_record" do
    let(:errors) { mock(:errors, full_messages: []) }
    let(:record) { mock(:record, attributes: {title: "Hi", internal_identifier: ["record123"]}, valid?: true, raw_data: "</record>", errors: errors, full_raw_data: "</record>") }

    before { record.stub(:deletable?) { false } }

    it "posts the record to the api with job_id" do
      worker.should_receive(:post_to_api).with({title: "Hi", internal_identifier: ["record123"], job_id: job.id})
      worker.process_record(record, job)
    end

    it "doesn't post to the API on a test harvest" do
      job.stub(:test?) { true }
      worker.should_not_receive(:post_to_api).with(record)
      worker.process_record(record, job)
    end
    
    it "increments records_count" do
      worker.stub(:post_to_api) 
      worker.process_record(record, job)
      job.records_count.should eq 1
    end

    it "saves the job" do
      job.should_receive(:save)
      worker.process_record(record, job)
    end

    it "stores invalid record's raw data" do
      record.stub(:valid?) { false }
      errors.stub(:full_messages) { ["Title can't be blank"] }
      worker.process_record(record, job)
      job.invalid_records.first.raw_data.should eq "</record>"
      job.invalid_records.first.error_messages.should eq ["Title can't be blank"]
    end

    it "rescues exceptions from a record and adds it to the failed records" do
      worker.stub(:post_to_api).and_raise "Post failed"
      worker.process_record(record, job)
      job.failed_records.first.message.should eq "Post failed"
    end

    context "deleteable record " do

      before { record.stub(:deletable?) { true } }

      it "deletes_from_api if the record is deletable?" do
        worker.should_receive(:delete_from_api).with(["record123"])
        worker.process_record(record, job)
      end

      it "does not post to api" do
        worker.should_not_receive(:post_to_api)
        worker.process_record(record, job)
      end
    end
  end

  describe "#post_to_api" do
    let(:attributes) { {title: "Hi"} }

    it "should post to the API" do
      job.stub(:required_enrichments) { }
      worker.post_to_api(attributes)
      expect(ApiUpdateWorker).to have_enqueued_job("/harvester/records.json", {record: attributes, required_sources: nil}, job.id)
    end

    context "required sources" do
      it "should send the required enricments to the api" do
        job.stub(:required_enrichments) { [:ndha_rights] }
        worker.post_to_api(attributes)
        expect(ApiUpdateWorker).to have_enqueued_job("/harvester/records.json", {record: attributes, required_sources: [:ndha_rights]}, job.id)
      end
    end
  end

  describe "#delete_from_api" do
    it "should send a delete to the api" do
      worker.delete_from_api(["abc123"])
      expect(ApiDeleteWorker).to have_enqueued_job("abc123")
    end
  end
end
