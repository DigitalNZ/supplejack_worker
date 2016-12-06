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

  before { Sidekiq.stub(:redis).and_yield(conn) }

  describe '#perform' do
    after(:each) { worker.perform(link_check_job.id.to_s) }

    it 'finds the link check job' do
      expect(LinkCheckJob).to receive(:find).with(link_check_job.id.to_s)
    end

    context 'job and source exist for worker' do
      before do
        worker.stub(:link_check_job) { link_check_job }
        link_check_job.stub_chain(:source, :_id) { 'abc123' }
        worker.stub(:rules) { link_check_rule }
        worker.stub(:link_check) { response }
      end

      it 'finds the link check rule' do
        expect(worker).to receive(:rules)
      end

      it 'checks if rule is present' do
        expect(link_check_rule).to receive(:present?)
      end

      it 'checks if rule is active' do
        expect(link_check_rule).to receive(:active)
      end

      it 'notifies an airbrake error when rule not present' do
        link_check_rule.stub(:present?) { false }
        expect(Airbrake).to receive(:notify).with(MissingLinkCheckRuleError.new(link_check_job.source_id))
      end

      it 'dosent call link check if rule is not active' do
        link_check_rule.stub(:active) { false }
        expect(worker).to_not receive(:link_check)
      end

      it 'calls the link check method' do
        expect(worker).to receive(:link_check).with(link_check_job.url, link_check_job.source._id)
      end

      context 'when response is nil' do
        before { worker.stub(:link_check) { nil } }

        it 'suppresse the record with strike 0' do
          expect(worker).to receive(:suppress_record).with(link_check_job.id.to_s,
                                                           link_check_job.record_id, 0)
        end
      end

      context 'when response is not nil' do
        before { worker.stub(:link_check) { response } }

        it 'validates the response' do
          expect(worker).to receive(:validate_link_check_rule).with(response,
                                                                    link_check_job.source._id)
        end

        context 'and response is invalid' do
          before { worker.stub(:validate_link_check_rule) { false} }

          it 'suppresse the record with strike 0' do
            expect(worker).to receive(:suppress_record).with(link_check_job.id.to_s,
                                                           link_check_job.record_id, 0)
          end
        end

        context 'and response is valid' do
          before { worker.stub(:validate_link_check_rule) { true} }

          context 'and strike is greated than 1' do
            after { worker.perform(link_check_job.id.to_s, 1) }

            it 'updates the record as active' do
              expect(worker).to receive(:set_record_status).with(link_check_job.record_id,
                                                                 'active')
            end
          end      
        end

        context 'exceptions' do
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
    end
  end

  describe '#link_check' do
    context 'when throttle limit succeeds' do
      before do
        conn.stub(:setnx) { true }
        conn.stub(:expire) { true }
        worker.stub(:rules) { link_check_rule }
      end

      after { worker.send(:link_check, 'http://boost.co.nz', 'some') }

      # The next request can be made only when this value expires
      it 'sets an expiry for redis value with throttle of the rule' do
        expect(conn).to receive(:expire).with('some', link_check_rule.throttle)
      end

      it 'sets the expiry value as default 2 when the rules has no throlltle' do
        link_check_rule.stub(:throttle) { nil }
        expect(conn).to receive(:expire).with('some', 2)
      end

      it 'makes a restclient get call with url' do
        expect(RestClient).to receive(:get).with('http://boost.co.nz')
      end

      context 'when restclient request fails with exception' do
        before { RestClient.stub(:get).and_raise { RestClient::ResourceNotFound.new('Something Wrong') } }

        it 'returns nil' do
          expect(worker.send(:link_check, 'http://boost.co.nz', 'some')).to eq nil
        end
      end

      context 'when requestclient request succeeds' do
        before { RestClient.stub(:get) { response } }

        it 'returns response' do
          expect(worker.send(:link_check, 'http://boost.co.nz', 'some')).to eq response
        end
      end
    end

    context 'when throttle limit fails' do
      before { conn.stub(:setnx) { false } }

      it 'raises an ThrottleLimitError' do
         expect { worker.send(:link_check, 'http://boost.co.nz', 'some') }.to raise_error(ThrottleLimitError)
      end
    end
  end

  describe '#set_record_status' do
    before { RestClient.stub(:put) }
    after { worker.send(:set_record_status, '123', 'deleted') }

    it 'makes a http PUT call with restclinet to the API_HOST' do
      expect(RestClient).to receive(:put).with("#{ENV['API_HOST']}/harvester/records/123",
                                               { record: { status: 'deleted'}})
    end
  end

  # describe "add_record_stats" do

  #   let(:collection_statistics) { double(:collection_statistics) }

  #   before do
  #     worker.stub(:link_check_job) { link_check_job }
  #     worker.stub(:collection_stats) { collection_statistics }
  #   end

  #   it "should add record stats for 'deleted'" do
  #     collection_statistics.should_receive(:add_record!).with(12345, 'deleted', "http://google.co.nz")
  #     worker.send(:add_record_stats,12345, 'deleted')
  #   end

  #   it "should add record stats for 'suppressed'" do
  #     collection_statistics.should_receive(:add_record!).with(12345, 'suppressed', "http://google.co.nz")
  #     worker.send(:add_record_stats,12345, 'suppressed')
  #   end

  #   it "should add record stats for 'active'" do
  #     collection_statistics.should_receive(:add_record!).with(12345, 'activated', "http://google.co.nz")
  #     worker.send(:add_record_stats,12345, 'active')
  #   end
  # end

  # describe "#collection_statistics" do

  #   let(:collection_statistics) { double(:collection_statistics).as_null_object }
  #   let(:relation) { double(:relation) }

  #   before do
  #     worker.stub(:link_check_job) { link_check_job }
  #     worker.instance_variable_set(:@link_check_job_id, link_check_job.id)
  #   end

  #   it "should find or create a collection statistics model with the collection_title" do
  #     CollectionStatistics.should_receive(:find_or_create_by).with({day: Date.today, source_id: link_check_job.source_id}) { collection_statistics }
  #     worker.send(:collection_stats).should eq collection_statistics
  #   end

  #   it "memoizes the result" do
  #     CollectionStatistics.should_receive(:find_or_create_by).once { collection_statistics }
  #     worker.send(:collection_stats)
  #     worker.send(:collection_stats)
  #   end
  # end

  # describe "link_check_job" do

  #   before { worker.instance_variable_set(:@link_check_job_id, link_check_job.id) }
    
  #   it "memoizes the result" do
  #     LinkCheckJob.should_receive(:find).once { link_check_job }
  #     worker.send(:link_check_job)
  #     worker.send(:link_check_job)
  #   end
  # end


  # describe "#suppress_record" do

  #   before { RestClient.stub(:put) }

  #   it "should make a post to the api to change the status to supressed for the record" do
  #     RestClient.should_receive(:put).with("#{ENV['API_HOST']}/harvester/records/abc123", {record: { status: 'suppressed' }})
  #     worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 0)
  #   end

  #   it "should trigger a new link_check_job with a strike of 1" do
  #     LinkCheckWorker.should_receive(:perform_in).with(1.hours, link_check_job.id.to_s, 1)
  #     worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 0)
  #   end

  #   it "should not trigger a job after the third strike" do
  #     LinkCheckWorker.should_not_receive(:perform_in)
  #     worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 100)
  #   end

  #   it "should not trigger a job on the third strike" do
  #     LinkCheckWorker.should_not_receive(:perform_in)
  #     worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 3)
  #   end

  #   it "should not send a request to set the record to 'suppressed' if the strike is over 0 " do
  #     worker.should_not_receive(:set_record_status).with("abc123", "suppressed")
  #     worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 1)
  #   end

  #   context "strike timings" do
  #     it "should perform the job in 1 hours on the 0th strike" do
  #       LinkCheckWorker.should_receive(:perform_in).with(1.hours, link_check_job.id.to_s, 1)
  #       worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 0)
  #     end

  #     it "should perform the job in 5 hours on the 1th strike" do
  #       LinkCheckWorker.should_receive(:perform_in).with(5.hours, link_check_job.id.to_s, 2)
  #       worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 1)
  #     end

  #     it "should perform the job in 72 hours on the 2nd strike" do
  #       LinkCheckWorker.should_receive(:perform_in).with(72.hours, link_check_job.id.to_s, 3)
  #       worker.send(:suppress_record, link_check_job.id.to_s, "abc123", 2)
  #     end
  #   end

  #   context "strike three your out!" do
  #     it "should set the status of the record to deleted" do
  #       worker.should_receive(:set_record_status).with("abc123", "deleted")
  #       worker.send(:suppress_record, link_check_job.id.to_s.to_s, "abc123", 3)
  #     end
  #   end
  # end

  # describe "set_record_status" do

  #   before { RestClient.stub(:put) }

  #   it "should make a post to the api to change the status to active for the record" do
  #     RestClient.should_receive(:put).with("#{ENV['API_HOST']}/harvester/records/abc123", {record: { status: 'active' }})
  #     worker.send(:set_record_status, "abc123", "active")
  #   end

  #   it "should add_record_stats" do
  #     worker.should_receive(:add_record_stats).with(12345, "active")
  #     worker.send(:set_record_status, 12345, "active")
  #   end
  # end

  # describe "#rules" do
  #   before do
  #     link_check_job.stub_chain(:source, :_id) { 'abc123' }
  #   end

  #   it "should call link_check_rule with the source_id" do
  #     worker.unstub(:rules)
  #     worker.should_receive(:link_check_job) { link_check_job }
  #     worker.should_receive(:link_check_rule).with('abc123') { link_check_rule }
  #     worker.send(:rules).should eq link_check_rule
  #   end
  # end

end
