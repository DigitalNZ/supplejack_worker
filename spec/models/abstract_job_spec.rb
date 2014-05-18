# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

describe AbstractJob do
  
  let(:job) { FactoryGirl.create(:abstract_job, parser_id: "12345", version_id: "666") }

  describe ".search" do
    let!(:active_job) { FactoryGirl.create(:abstract_job, status: "active") }

    it "returns all active harvest jobs" do
      finished_job = FactoryGirl.create(:abstract_job, status: "finished")
      AbstractJob.search("status" => "active").should eq [active_job]
    end

    it "paginates through the records" do
      AbstractJob.should_receive(:page).with(2) { AbstractJob.unscoped }
      AbstractJob.search("status" => "active", "page" => "2").to_a
    end

    it "returns the recent harvest jobs first" do
      active_job2 = FactoryGirl.create(:abstract_job, status: "active", start_time: Time.now + 5.seconds)
      AbstractJob.search("status" => "active").first.should eq active_job2
    end

    it "returns only test harvest jobs of a specific parser" do
      job2 = FactoryGirl.create(:abstract_job, parser_id: "333", environment: "test")
      AbstractJob.search("parser_id" => "333", "environment" => "test").should eq [job2]
    end

    it "limits the number of harvest jobs returned" do
      job2 = FactoryGirl.create(:abstract_job, parser_id: "333", environment: "test", start_time: Time.now + 5.seconds)
      AbstractJob.search("limit" => "1").to_a.size.should eq 1
    end

    it "should find all harvest jobs either in staging or production" do
      job1 = FactoryGirl.create(:abstract_job, parser_id: "333", environment: "staging", start_time: Time.now)
      job2 = FactoryGirl.create(:abstract_job, parser_id: "334", environment: "production", start_time: Time.now + 2.seconds)
      jobs = AbstractJob.search("environment" => ["staging", "production"]).to_a
      jobs.should include(job2)
      jobs.should include(job1)
    end
  end

  describe ".clear_raw_data" do
    it "should fetch harvest jobs older than a week" do
      AbstractJob.should_receive(:disposable) { [job] }
      job.should_receive(:clear_raw_data)
      AbstractJob.clear_raw_data
    end
  end

  describe "#parser" do
    let!(:version) { mock_model(ParserVersion).as_null_object }

    it "returns @parser if @parser is set" do
      job.instance_variable_set(:@parser, 'a parser!')
      job.parser.should eq 'a parser!'
    end

    context "with version_id" do
      it "finds the parser by id" do
        ParserVersion.should_receive(:find).with("666", params: {parser_id: "12345"})
        job.parser
      end
    end

    context "without version_id" do
      before(:each) do
        job.version_id = ""
        job.environment = "staging"
      end

      it "finds the current parser version for the environment" do
        ParserVersion.should_receive(:find).with(:one, from: :current, params: {parser_id: "12345", environment: "staging"}) { version }
        job.parser
      end

      it "should set the version_id of the fetched version" do
        ParserVersion.should_receive(:find) { mock_model(ParserVersion, id: "888").as_null_object }
        job.parser
        job.version_id.should eq "888"
      end

      context "the environment is preview and parser_code is present" do
        let(:parser) {double(:parser).as_null_object}
        before(:each) do
          job.environment = "preview"
          job.parser_code = "new code"
          Parser.stub(:find) {parser}
        end

        it "finds the parser by id" do
          Parser.should_receive(:find).with("12345")
          job.parser
        end

        it "sets the parser content to parser_code" do
          parser.should_receive(:content=).with("new code")
          job.parser
        end
      end
    end

    context "without version_id and environment" do
      before do 
        job.version_id = ""
        job.environment = nil
      end

      it "finds the parser by id" do
        Parser.should_receive(:find).with("12345")
        job.parser
      end
    end
  end

  describe "#required_enrichments" do
    it "should return an array of enrichments with required: true" do
      job.stub_chain(:parser, :enrichment_definitions).and_return({ndha_rights: {required_for_active_record: true}, thumbnails: {} })
      job.required_enrichments.should eq [:ndha_rights]
    end
  end

  describe "status" do
    describe "initial" do
      it "should set the initial status to active" do
        job.ready?.should be_true
      end
    end

    describe "start!" do
      it "should set the status to active" do
        job.start!
        job.active?.should be_true
      end

      it "should set the start time to now" do
        time = Time.now
        Timecop.freeze(time) do
          job.start!
          job.reload
          job.start_time.to_i.should eq time.to_i
        end
      end

      it "should set the records count to 0" do
        job.start!
        job.records_count.should eq 0
      end

      it "should set the processed count to 0" do
        job.start!
        job.processed_count.should eq 0
      end

      it "should save the job" do
        job.should_receive(:save) { true }
        job.start!
      end
    end

    describe "finish!" do
      it "should set the status to finished" do
        job.finish!
        job.finished?.should be_true
      end

      it "should set the end time to now" do
        time = Time.now
        Timecop.freeze(time) do
          job.finish!
          job.reload
          job.end_time.to_i.should eq time.to_i
        end
      end

      it "should set the throughput" do
        job.should_receive(:calculate_throughput)
        job.finish!
      end

      it "should set the errors count" do
        job.should_receive(:calculate_errors_count)
        job.finish!
      end

      it "should save the job" do
        job.should_receive(:save) { true }
        job.finish!
      end
    end

    describe "error!" do
      it "should set the status to failed" do
        job.error!
        job.failed?.should be_true
      end

      context "start time" do
        it "should set the start time to now if not set" do
          time = Time.now
          Timecop.freeze(time) do
            job.error!
            job.reload.end_time.to_i.should eq time.to_i
          end
        end

        it "should not set the start time to now if set" do
          Timecop.freeze(Time.now - 1.hour) do
            job.start!
          end

          time = Time.now
          Timecop.freeze(time) do
            job.error!
            job.reload.start_time.to_i.should_not eq time.to_i
          end
        end
        
      end

      it "should set the end time to now" do
        job.start!

        time = Time.now
        Timecop.freeze(time) do
          job.error!
          job.reload.end_time.to_i.should eq time.to_i
        end
      end

      it "should set the errors count" do
        job.should_receive(:calculate_errors_count)
        job.error!
      end

      it "should save the job" do
        job.should_receive(:save) { true }
        job.error!
      end
    end

    describe "stop!" do
      before(:each) do
        job.start!
      end

      it "should set the status to failed" do
        job.stop!
        job.stopped?.should be_true
      end

      it "should set the end time to now" do
        time = Time.now
        Timecop.freeze(time) do
          job.stop!
          job.reload.end_time.to_i.should eq time.to_i
        end
      end

      it "should save the job" do
        job.should_receive(:save) { true }
        job.stop!
      end
    end
  end

  describe "test?" do
    it "returns true" do
      job.environment = "test"
      job.test?.should be_true
    end

    it "returns false" do
      job.environment = "staging"
      job.test?.should be_false
    end
  end

  describe "#preview?" do
    it "returns true" do
      job.environment = "preview"
      job.preview?.should be_true
    end

    it "returns false" do
      job.environment = "staging"
      job.preview?.should be_false
    end
  end

  describe "calculate_throughput" do
    before(:each) do
      job.end_time = Time.now
      job.status = "finished"
    end

    it "should calculate the average record time" do
      job.records_count = 100
      job.stub(:duration) { 100 }
      job.calculate_throughput
      job.throughput.should eq 1.0
    end

    it "returns 0 when records harvested is 0" do
      job.records_count = 0
      job.stub(:duration) { 100 }
      job.calculate_throughput
      job.throughput.should eq 0
    end

    it "should not return NaN" do
      job.records_count = 0
      job.stub(:duration) { 0.0 }
      job.calculate_throughput
      job.throughput.should be_nil
    end
  end

  describe ".jobs_since" do

    let!(:finished_job) { FactoryGirl.create(:abstract_job, status: "finished", start_time: (DateTime.now - 1), environment: "staging" ) }
 
    it "returns a count of harvest jobs in the last 2 days" do
      old_finished_job = FactoryGirl.create(:abstract_job, status: "finished", start_time: (DateTime.now - 3), environment: "staging" )
      since = DateTime.now - 2
      AbstractJob.jobs_since( {'datetime'=>since.to_s, 'environment'=>'staging', 'status'=>'finished'} ).should eq [finished_job]
    end

  end

  describe "#duration" do
    let!(:time) { Time.now }

    it "should return the duration in seconds" do
      job.start_time = time - 10.seconds
      job.end_time = time
      job.save
      job.reload
      job.duration.should eq 10.0
    end

    it "returns nil start_time is nil" do
      job.start_time = nil
      job.duration.should be_nil
    end

    it "returns nil end_time is nil" do
      job.end_time = nil
      job.duration.should be_nil
    end

    it "returns the proper duration" do
      time = Time.now
      Timecop.freeze(time) do
        job = FactoryGirl.create(:abstract_job, start_time: time)
        job.end_time = Time.now + 5.seconds
        job.duration.should eq 5
      end
    end
  end

  describe "total_errors_count" do
    it "should return a sum of failed and invalid records" do
      job.stub(:invalid_records) { double(:array, count: 10) }
      job.stub(:failed_records) { double(:array, count: 20) }
      job.total_errors_count.should eq 30
    end
  end

  describe "#errors_over_limit?" do
    context "errors count over 100" do
      before { job.stub(:total_errors_count) { 101 } }

      it "should return true" do
        job.errors_over_limit?.should be_true
      end
    end

    context "errors count under 100" do
      before { job.stub(:total_errors_count) { 99 } }

      it "should return false" do
        job.errors_over_limit?.should be_false
      end
    end
  end

  describe "clear_raw_data" do
    it "should remove invalid records" do
      job.invalid_records.create(raw_data: "Wrong", errors_messages: [])
      job.clear_raw_data
      job.reload
      job.invalid_records.count.should eq 0
    end

    it "should remove failed records" do
      job.failed_records.create(message: "Hi")
      job.clear_raw_data
      job.reload
      job.failed_records.count.should eq 0
    end
  end

  describe "#increment_records_count!" do
    it "should increment the records count" do
      job.increment_records_count!
      job.reload
      job.records_count.should eq 1
    end
  end

  describe "#increment_processed_count!" do
    it "should increment the records count" do
      job.increment_processed_count!
      job.reload
      job.processed_count.should eq 1
    end
  end

end