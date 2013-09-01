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
    let!(:record) { double(:record, attributes: {}, valid?: true) }

    before(:each) do
      job.stub(:parser) { parser }
      LoadedParser::NatlibPages.stub(:records) { [record] }
      worker.stub(:api_update_finished?) { true }
      worker.stub(:process_record)
    end

    it "processes each record" do
      worker.should_receive(:process_record).with(record, job)
      worker.perform(1)
    end

    it "enqueues enrichment jobs" do
      job.should_receive(:enqueue_enrichment_jobs)
      worker.perform(1)
    end

    it "sets @job_id to the harvest_job_id" do
      worker.perform("abc123")
      worker.job_id.should eq "abc123"
    end

    it "handles ids as objects" do
      worker.perform({"$oid" => "abc123"})
      worker.job_id.should eq "abc123"
    end
  end

  describe "#process_record" do
    let(:errors) { double(:errors, full_messages: []) }
    let(:record) { double(:record, attributes: {title: "Hi", internal_identifier: ["record123"]}, valid?: true, raw_data: "</record>", errors: errors, full_raw_data: "</record>") }

    before { record.stub(:deletable?) { false } }

    it "posts the record to the api with job_id" do
      worker.should_receive(:post_to_api).with({title: "Hi", internal_identifier: ["record123"], job_id: job.id.to_s })
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
    let(:attributes) { {"title" => "Hi"} }

    it "should post to the API" do
      job.stub(:required_enrichments) { }
      worker.post_to_api(attributes)
      expect(ApiUpdateWorker).to have_enqueued_job("/harvester/records.json", {"record" => attributes, "required_fragments" => nil}, job.id.to_s)
    end

    context "async false" do

      let(:api_update_worker) { double(:api_update_worker) }

      it "should create a new instance of ApiUpdateWorker" do
        job.stub(:required_enrichments)
        ApiUpdateWorker.should_receive(:new) { api_update_worker }
        api_update_worker.should_receive(:perform)
        worker.post_to_api(attributes, false)
      end
    end

    context "required fragments" do
      it "should send the required enricments to the api" do
        job.stub(:required_enrichments) { [:ndha_rights] }
        worker.post_to_api(attributes)
        expect(ApiUpdateWorker).to have_enqueued_job("/harvester/records.json", {"record" => attributes, "required_fragments" => ["ndha_rights"]}, job.id.to_s)
      end
    end
  end

  describe "#delete_from_api" do
    it "should send a delete to the api" do
      worker.delete_from_api(["abc123"])
      expect(ApiDeleteWorker).to have_enqueued_job("abc123", job.id.to_s)
    end
  end
end
