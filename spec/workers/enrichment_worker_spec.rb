require "spec_helper"

describe EnrichmentWorker do

  class TestClass
    class_attribute :environment
    def self.get_source_id; "nlnzcat"; end
  end

  let(:worker) { EnrichmentWorker.new }
  let(:job) { FactoryGirl.create(:enrichment_job, environment: "production", enrichment: "ndha_rights") }
  let(:parser) { mock(:parser, loader: mock(:loader, parser_class: TestClass)).as_null_object }

  before(:each) do
    job.stub(:parser) { parser }
    worker.stub(:enrichment_job) { job }
  end

  describe "#perform" do

    it "should set the @enrichment_job_id" do
      worker.perform(1234)
      worker.instance_variable_get("@enrichment_job_id").should eq 1234
    end

    it "should mark the job as started" do
      job.should_receive(:start!)
      worker.perform(1234)
    end

    it "should setup the parser" do
      worker.stub(:records) { [] }
      worker.should_receive(:setup_parser)
      worker.perform(1234)
    end

    it "should process every record" do
      record = mock(:record)
      worker.stub(:records) { [record] }
      worker.should_receive(:process_record).with(record)
      worker.perform(1234)
    end

    it "should finish the enrichment_job" do
      job.should_receive(:finish!)
      worker.perform(1234)
    end

    it "stops processing the records" do
      worker.stub(:stop_harvest?) { true }
      worker.should_not_receive(:process_record)
      worker.perform(1)
    end
  end
  
  describe "#enrichment_job" do
    it "should find the enrichment job" do
      worker.instance_variable_set("@enrichment_job_id", job.id)
      worker.enrichment_job.should eq job
    end
  end

  describe "#records" do
    before(:each) do
      worker.send(:setup_parser)
    end

    it "should fetch records based on the source_id" do
      TestClass.stub(:get_source_id) { "nlnzcat" }
      DnzApi::Record.should_receive(:where).with("sources.source_id" => "nlnzcat")
      worker.records
    end
  end

  describe "#process_record" do
    let(:record) { mock(:record).as_null_object }
    let(:enrichment) { mock(:enrichment).as_null_object }

    before do
      worker.send(:setup_parser)
      HarvesterCore::Enrichment.stub(:new) { enrichment }
      worker.stub(:post_to_api) { nil }
    end

    it "should initialize a enrichment" do
      HarvesterCore::Enrichment.should_receive(:new).with("ndha_rights", worker.send(:enrichment_block), record, TestClass)
      worker.process_record(record)
    end

    it "should set the enrichment attributes" do
      enrichment.should_receive(:set_attribute_values)
      worker.process_record(record)
    end

    it "should post to the api" do
      worker.should_receive(:post_to_api).with(enrichment)
      worker.process_record(record)
    end

    it "should post to the api in a test environment" do
      job.stub(:test?) { true }
      worker.should_not_receive(:post_to_api).with(enrichment)
      worker.process_record(record)
    end

    it "should increment the records count on the job" do
      job.should_receive(:increment_records_count!)
      worker.process_record(record)
    end

    it "should rescue from a exception in processing the record" do
      enrichment.stub(:set_attribute_values).and_raise(StandardError.new("Hi"))
      worker.process_record(record)
    end
  end

  describe "#setup_parser" do
    it "should initialize a parser" do
      worker.send(:setup_parser)
      worker.parser.should eq parser
    end

    it "should load the parser file" do
      parser.should_receive(:load_file)
      worker.send(:setup_parser)
    end

    it "should initialize the parser class" do
      worker.send(:setup_parser)
      worker.parser_class.should eq TestClass
    end

    it "should set the environment of the job to the parser_class" do
      worker.send(:setup_parser)
      worker.parser_class.environment.should eq "production"
    end
  end

  describe "#enrichment_block" do
    let(:block) { Proc.new { "Hi" } }

    before(:each) do
      parser.stub(:enrichment_definitions) { {ndha_rights: block} }
    end

    it "should fetch the enrichment definition block" do
      job.enrichment = "ndha_rights"
      worker.send(:setup_parser)
      worker.send(:enrichment_block).should eq block
    end
  end
end