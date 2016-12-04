# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

describe LinkCheckWorker do

  let(:worker) { LinkCheckWorker.new }
  let(:link_check_job) { FactoryGirl.create(:link_check_job)  }
  let(:response) { double(:response) }
  let(:link_check_rule) { double(:link_check_rule, status_codes: "200, 3..", xpath: '//p', throttle: 3, active: true) }
  let(:conn) { double(:conn) }

  before do
    worker.stub(:rules) { link_check_rule }
    Sidekiq.stub(:redis).and_yield(conn)
  end

  describe "#perform" do
    before do
      link_check_job.stub_chain(:source, :_id) { 'abc123' }
      worker.stub(:link_check_job) { link_check_job }
    end

    it "should perform a link_check" do
      worker.should_receive(:link_check).with(link_check_job.url, link_check_job.source._id)
      worker.perform(link_check_job.id.to_s)
    end

    context "validate_link_check_rule returns false" do
      before { worker.stub(:link_check) { response } }
      it "should supress the record" do
        worker.stub(:validate_link_check_rule) { false }
        worker.should_receive(:suppress_record).with(link_check_job.id.to_s, link_check_job.record_id, 0)
        worker.perform(link_check_job.id.to_s)
      end
    end

    context "validate_link_check_rule returns true" do
      before { worker.stub(:link_check) { response } }

      it "should not set the record status if on the 0th strike" do
        worker.should_not_receive(:set_record_status).with(link_check_job.record_id, "active")
        worker.stub(:validate_link_check_rule) { true }
        worker.perform(link_check_job.id.to_s)
      end

      it "should reactivate the record if strike is greater than 0" do
        worker.should_receive(:set_record_status).with(link_check_job.record_id, "active")
        worker.stub(:validate_link_check_rule) { true }
        worker.perform(link_check_job.id.to_s, 1)
      end
    end
    
    context "link checking not active for collection" do
      before do
        worker.stub(:link_check_job) { link_check_job }
        link_check_rule.stub(:active) { false }
      end

      it "should not check the link" do
        worker.should_not_receive(:link_check)
        worker.perform("anc123")
      end
    end

    context "link check rule doesn't exist" do
      let(:logger) { double(:logger) }

      before(:each) do
        worker.stub(:rules) { nil }
        worker.stub_chain(:link_check_job, :source) { double(:source) }
        Sidekiq.stub(:logger) { logger }
        logger.stub(:error)
        logger.stub(:info)
      end

      it "should send a MissingLinkCheckRuleError to Airbrake with the missing source_id" do
        MissingLinkCheckRuleError.should_receive(:new).with('tapuhi')
        Airbrake.should_receive(:notify)
        worker.perform(link_check_job.id.to_s)
      end

      it "should return if the rule isn't found" do
        Airbrake.should_receive(:notify).once()
        worker.perform(link_check_job.id.to_s)
      end

      it "should write the source_id to the log file" do
        logger.should_receive(:error).with("MissingLinkCheckRuleError: No LinkCheckRule found for source_id: [tapuhi]")
        worker.perform(link_check_job.id.to_s)
      end
    end

    context "link check job not found" do
      it "should not check the link" do
        worker.stub(:link_check_job) { nil }
        worker.should_not_receive(:link_check)
        worker.perform("anc123")
      end
    end

    context "exceptions" do
      it "should sends a request to the DNZ API updating the status of the record to 'supressed' on a 404 error" do
        worker.stub(:link_check).and_raise(RestClient::ResourceNotFound.new("url not work bro")) 
        worker.should_receive(:suppress_record).with(link_check_job.id.to_s, link_check_job.record_id, 0)
        worker.perform(link_check_job.id.to_s)
      end

      it 'handles throttling error' do
        worker.stub(:link_check).and_raise(ThrottleLimitError.new('ThrottleLimitError'))
        expect { worker.perform(link_check_job.id.to_s) }.to_not raise_exception
      end
      
      it "should handle networking errors" do
        worker.stub(:link_check).and_raise(StandardError.new('RestClient Exception'))
        expect {worker.perform(link_check_job.id.to_s)}.to_not raise_exception
      end
    end
  end

  describe "add_record_stats" do

    let(:collection_statistics) { double(:collection_statistics) }

    before do
      worker.stub(:link_check_job) { link_check_job }
      worker.stub(:collection_stats) { collection_statistics }
    end

    it "should add record stats for 'deleted'" do
      collection_statistics.should_receive(:add_record!).with(12345, 'deleted', "http://google.co.nz")
      worker.send(:add_record_stats,12345, 'deleted')
    end

    it "should add record stats for 'suppressed'" do
      collection_statistics.should_receive(:add_record!).with(12345, 'suppressed', "http://google.co.nz")
      worker.send(:add_record_stats,12345, 'suppressed')
    end

    it "should add record stats for 'active'" do
      collection_statistics.should_receive(:add_record!).with(12345, 'activated', "http://google.co.nz")
      worker.send(:add_record_stats,12345, 'active')
    end
  end

  describe "#collection_statistics" do

    let(:collection_statistics) { double(:collection_statistics).as_null_object }
    let(:relation) { double(:relation) }

    before do
      worker.stub(:link_check_job) { link_check_job }
      worker.instance_variable_set(:@link_check_job_id, link_check_job.id)
    end

    it "should find or create a collection statistics model with the collection_title" do
      CollectionStatistics.should_receive(:find_or_create_by).with({day: Date.today, source_id: link_check_job.source_id}) { collection_statistics }
      worker.send(:collection_stats).should eq collection_statistics
    end

    it "memoizes the result" do
      CollectionStatistics.should_receive(:find_or_create_by).once { collection_statistics }
      worker.send(:collection_stats)
      worker.send(:collection_stats)
    end
  end

  describe "link_check_job" do

    before { worker.instance_variable_set(:@link_check_job_id, link_check_job.id) }
    
    it "memoizes the result" do
      LinkCheckJob.should_receive(:find).once { link_check_job }
      worker.send(:link_check_job)
      worker.send(:link_check_job)
    end
  end

  describe "#link_check" do

    let(:response) { double(:response) }

    before do 
      RestClient.stub(:get) { response }
      conn.stub(:setnx) { true }
      conn.stub(:expire)
      worker.stub(:link_check_rule) { link_check_rule }
    end

    it "should return the response" do
      worker.send(:link_check, "http://google.co.nz", "").should eq response
    end
    
    context "has the lock " do

      it "it sets the expire on the key & performs a rest client get" do
        conn.should_receive(:expire).with("TAPUHI", 3)
        RestClient.should_receive(:get).with("http://hehehe.com")
        worker.send(:link_check, "http://hehehe.com", "TAPUHI")
      end

      context "no collection rule for collection" do
        before { worker.stub(:rules) { nil } }

        it "throttle should be 2 seconds" do
          conn.should_receive(:expire).with("TAPUHI", 2)
          worker.send(:link_check, "http://hehehe.com", "TAPUHI")
        end
      end

      context "throttle is nil" do
        let(:link_check_rule) { double(:link_check_rule, status_codes: "200, 3..", xpath: '//p', throttle: nil) }

        it "throttle should default to 2 seconds if throttle is nil" do
          worker.stub(:link_check_rule) { link_check_rule }
          conn.should_receive(:expire).with("TAPUHI", 2)
          worker.send(:link_check, "http://hehehe.com", "TAPUHI")
        end
      end
    end

    context "does not have the lock" do
      before do
        conn.stub(:setnx) { false }
        Sidekiq.stub(:redis).and_yield(conn)
      end

      it "should throw an exception" do
        expect { worker.send(:link_check, "http://hehehe.com", "tapuhi") }.to raise_error(ThrottleLimitError)
      end
    end
  end

  describe "#suppress_record" do

    before { RestClient.stub(:put) }

    it "should make a post to the api to change the status to supressed for the record" do
      RestClient.should_receive(:put).with("#{ENV['API_HOST']}/harvester/records/abc123", {record: { status: 'suppressed' }})
      worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 0)
    end

    it "should trigger a new link_check_job with a strike of 1" do
      LinkCheckWorker.should_receive(:perform_in).with(1.hours, link_check_job.id.to_s, 1)
      worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 0)
    end

    it "should not trigger a job after the third strike" do
      LinkCheckWorker.should_not_receive(:perform_in)
      worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 100)
    end

    it "should not trigger a job on the third strike" do
      LinkCheckWorker.should_not_receive(:perform_in)
      worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 3)
    end

    it "should not send a request to set the record to 'suppressed' if the strike is over 0 " do
      worker.should_not_receive(:set_record_status).with("abc123", "suppressed")
      worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 1)
    end

    context "strike timings" do
      it "should perform the job in 1 hours on the 0th strike" do
        LinkCheckWorker.should_receive(:perform_in).with(1.hours, link_check_job.id.to_s, 1)
        worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 0)
      end

      it "should perform the job in 5 hours on the 1th strike" do
        LinkCheckWorker.should_receive(:perform_in).with(5.hours, link_check_job.id.to_s, 2)
        worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 1)
      end

      it "should perform the job in 72 hours on the 2nd strike" do
        LinkCheckWorker.should_receive(:perform_in).with(72.hours, link_check_job.id.to_s, 3)
        worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 2)
      end
    end

    context "strike three your out!" do
      it "should set the status of the record to deleted" do
        worker.should_receive(:set_record_status).with("abc123", "deleted")
        worker.send(:suppress_record, link_check_job.id.to_s.to_s, "abc123", 3)
      end
    end
  end

  describe "set_record_status" do

    before { RestClient.stub(:put) }

    it "should make a post to the api to change the status to active for the record" do
      RestClient.should_receive(:put).with("#{ENV['API_HOST']}/harvester/records/abc123", {record: { status: 'active' }})
      worker.send(:set_record_status, "abc123", "active")
    end

    it "should add_record_stats" do
      worker.should_receive(:add_record_stats).with(12345, "active")
      worker.send(:set_record_status, 12345, "active")
    end
  end

  describe "#rules" do
    before do
      link_check_job.stub_chain(:source, :_id) { 'abc123' }
    end

    it "should call link_check_rule with the source_id" do
      worker.unstub(:rules)
      worker.should_receive(:link_check_job) { link_check_job }
      worker.should_receive(:link_check_rule).with('abc123') { link_check_rule }
      worker.send(:rules).should eq link_check_rule
    end
  end

end
