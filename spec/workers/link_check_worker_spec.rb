# frozen_string_literal: true

require 'rails_helper'

describe LinkCheckWorker do
  let(:worker) { LinkCheckWorker.new }
  let(:link_check_job) { create(:link_check_job) }
  let(:response) { double(:response) }
  let(:link_check_rule) { double(:link_check_rule, status_codes: '200, 3..', xpath: '//p', throttle: 3, active: true) }
  let(:conn) { double(:conn) }

  before { allow(Sidekiq).to receive(:redis).and_yield(conn) }

  describe '#perform' do
    after(:each) { worker.perform(link_check_job.id.to_s) }

    it 'finds the link check job' do
      expect(LinkCheckJob).to receive(:find).with(link_check_job.id.to_s)
    end

    context 'when job and source exist' do
      before do
        allow(worker).to receive(:job).and_return(link_check_job)
        allow(link_check_job).to receive_message_chain(:source, :id).and_return('abc123')
        allow(worker).to receive(:rules).and_return(link_check_rule)
        allow(worker).to receive(:link_check).and_return(response)
      end

      it 'is a low priority job' do
        expect(worker.sidekiq_options_hash['queue']).to eq 'low'
      end

      it 'finds the link check rule' do
        expect(worker).to receive(:rules)
      end

      it 'checks if rule is present' do
        expect(link_check_rule).to receive(:blank?)
      end

      it 'checks if rule is active' do
        expect(link_check_rule).to receive(:active)
      end

      it 'notifies an ElasticAPM error when rule not present' do
        allow(link_check_rule).to receive(:blank?).and_return(true)

        expect(ElasticAPM).to receive(:report).with(MissingLinkCheckRuleError.new(link_check_job.source_id))
      end

      it 'dosent call link check if rule is not active' do
        allow(link_check_rule).to receive(:active).and_return(false)

        expect(worker).to_not receive(:link_check)
      end

      it 'calls the link check method' do
        expect(worker).to receive(:link_check).with(link_check_job.url, link_check_job.source.id)
      end

      context 'when response is nil' do
        before { allow(worker).to receive(:link_check) { nil } }

        it 'suppresse the record with strike 0' do
          expect(worker).to receive(:suppress_record).with(link_check_job.id.to_s,
                                                           link_check_job.record_id, 0)
        end
      end

      context 'when response is not nil' do
        before { allow(worker).to receive(:link_check).and_return(response) }

        it 'validates the response' do
          expect(worker).to receive(:validate_link_check_rule).with(response,
                                                                    link_check_job.source.id)
        end

        context 'when response is invalid' do
          before { allow(worker).to receive(:validate_link_check_rule).and_return(false) }

          it 'suppresse the record with strike 0' do
            expect(worker).to receive(:suppress_record).with(link_check_job.id.to_s,
                                                             link_check_job.record_id, 0)
          end
        end

        context 'when response is valid' do
          before { allow(worker).to receive(:validate_link_check_rule).and_return(true) }

          context 'when strike is greated than 1' do
            after { worker.perform(link_check_job.id.to_s, 1) }

            it 'updates the record as active' do
              expect(worker).to receive(:set_record_status).with(link_check_job.record_id,
                                                                 'active')
            end
          end
        end

        context 'when there is an exception' do
          it 'swallows ThrottleLimitError' do
            allow(worker).to receive(:link_check).and_raise(ThrottleLimitError.new('ThrottleLimitError'))

            expect { worker.perform(link_check_job.id.to_s) }.to_not raise_exception
          end

          it 'swallows RestClient Exception' do
            allow(worker).to receive(:link_check).and_raise(StandardError.new('RestClient Exception'))

            expect { worker.perform(link_check_job.id.to_s) }.to_not raise_exception
          end
        end
      end
    end
  end

  describe '#link_check' do
    context 'when throttle limit succeeds' do
      before do
        allow(conn).to receive(:setnx) { true }
        allow(conn).to receive(:expire) { true }
        allow(worker).to receive(:rules) { link_check_rule }
      end

      after { worker.send(:link_check, 'http://boost.co.nz', 'some') }

      # The next request can be made only when this value expires
      it 'sets an expiry for redis value with throttle of the rule' do
        expect(conn).to receive(:expire).with('some', link_check_rule.throttle)
      end

      it 'sets the expiry value as default 2 when the rules has no throlltle' do
        allow(link_check_rule).to receive(:throttle).and_return(nil)

        expect(conn).to receive(:expire).with('some', 2)
      end

      it 'makes a restclient get call with url' do
        expect(RestClient).to receive(:get).with('http://boost.co.nz')
      end

      context 'when restclient request fails with exception' do
        before { allow(RestClient).to receive(:get).and_raise { RestClient::ResourceNotFound.new('Something Wrong') } }

        it 'returns nil' do
          expect(worker.send(:link_check, 'http://boost.co.nz', 'some')).to eq nil
        end
      end

      context 'when requestclient request succeeds' do
        before { allow(RestClient).to receive(:get).and_return(response) }

        it 'returns response' do
          expect(worker.send(:link_check, 'http://boost.co.nz', 'some')).to eq response
        end
      end
    end

    context 'when throttle limit fails' do
      before { allow(conn).to receive(:setnx).and_return(false) }

      it 'raises an ThrottleLimitError' do
        expect { worker.send(:link_check, 'http://boost.co.nz', 'some') }.to raise_error(ThrottleLimitError)
      end
    end
  end

  describe '#set_record_status' do
    before { allow(RestClient).to receive(:put) }
    after  { worker.send(:set_record_status, '123', 'deleted') }

    it 'makes a http PUT call with RestClient to the API_HOST' do
      expect(RestClient::Request).to receive(:execute).with(
        method: :put,
        url: "#{ENV['API_HOST']}/harvester/records/123.json",
        payload: { record: { status: 'deleted' } },
        headers: { 'Authentication-Token': ENV['HARVESTER_API_KEY'] }
      )
    end
  end

  describe '#link_check_job' do
    before { worker.instance_variable_set(:@job_id, link_check_job.id) }

    it 'memoizes the link check job' do
      expect(LinkCheckJob).to receive(:find).once.with(link_check_job.id)

      worker.send(:job)
    end
  end

  describe 'add_record_stats' do
    let(:collection_statistics) { double(:collection_statistics) }

    before do
      allow(worker).to receive(:job).and_return(link_check_job)
      allow(worker).to receive(:collection_stats).and_return(collection_statistics)
    end

    it 'should add record stats for deleted' do
      expect(collection_statistics).to receive(:add_record!).with(12_345, 'deleted', 'http://google.co.nz')

      worker.send(:add_record_stats, 12_345, 'deleted')
    end

    it 'should add record stats for suppressed' do
      expect(collection_statistics).to receive(:add_record!).with(12_345, 'suppressed', 'http://google.co.nz')

      worker.send(:add_record_stats, 12_345, 'suppressed')
    end

    it 'should add record stats for active' do
      expect(collection_statistics).to receive(:add_record!).with(12_345, 'activated', 'http://google.co.nz')

      worker.send(:add_record_stats, 12_345, 'active')
    end
  end

  describe '#collection_statistics' do
    let(:collection_statistics) { double(:collection_statistics).as_null_object }
    let(:relation) { double(:relation) }

    before do
      allow(worker).to receive(:job).and_return(link_check_job)
      worker.instance_variable_set(:@job_id, link_check_job.id)
    end

    it 'should find or create a collection statistics model with the collection_title' do
      expect(CollectionStatistics).to receive(:find_or_create_by).with(day: Time.zone.today, source_id: link_check_job.source_id) {
 collection_statistics }
      expect(worker.send(:collection_stats)).to eq collection_statistics
    end

    it 'memoizes the result' do
      expect(CollectionStatistics).to receive(:find_or_create_by).once.and_return(collection_statistics)

      worker.send(:collection_stats)
    end
  end

  describe '#suppress_record' do
    before { allow(RestClient).to receive(:put) }

    it 'should make a post to the api to change the status to supressed for the record' do
      expect(RestClient::Request).to receive(:execute).with(
        method: :put,
        url: "#{ENV['API_HOST']}/harvester/records/abc123.json",
        payload: { record: { status: 'suppressed' } },
        headers: { 'Authentication-Token': ENV['HARVESTER_API_KEY'] }
      )

      worker.send(:suppress_record, link_check_job.id.to_s, 'abc123', 0)
    end

    it 'should trigger a new link_check_job with a strike of 1' do
      expect(LinkCheckWorker).to receive(:perform_in).with(1.hours, link_check_job.id.to_s, 1)

      worker.send(:suppress_record, link_check_job.id.to_s, link_check_job.id, 0)
    end

    it 'should not send a request to set the record to suppressed if the strike is over 0 ' do
      expect(worker).to_not receive(:set_record_status).with(link_check_job.id, 'suppressed')

      worker.send(:suppress_record, link_check_job.id.to_s, link_check_job.id, 1)
    end

    describe 'check intervals' do
      it 'should schedule a job to run in 1 hours on the first strike' do
        expect(LinkCheckWorker).to receive(:perform_in).with(1.hours, link_check_job.id.to_s, 1)

        worker.send(:suppress_record, link_check_job.id.to_s, link_check_job.id, 0)
      end

      it 'should schedule a job to run in 23 hours on the second strike' do
        expect(LinkCheckWorker).to receive(:perform_in).with(23.hours, link_check_job.id.to_s, 2)

        worker.send(:suppress_record, link_check_job.id.to_s, link_check_job.id, 1)
      end

      it 'should not schedule a job after the third strike' do
        expect(LinkCheckWorker).to_not receive(:perform_in)

        worker.send(:suppress_record, link_check_job.id.to_s, link_check_job.id, 2)
      end
    end

    context 'when strike is the third or more' do
      it 'should set the status of the record to deleted' do
        expect(worker).to receive(:set_record_status).with('abc123', 'deleted')

        worker.send(:suppress_record, link_check_job.id.to_s.to_s, 'abc123', 2)
      end
    end
  end

  describe '#rules' do
    before { allow(link_check_job).to receive_message_chain(:source, :id).and_return('abc123') }

    it 'should call link_check_rule with the source_id' do
      expect(worker).to receive(:job) { link_check_job }
      expect(worker).to receive(:link_check_rule).with('abc123') { link_check_rule }

      expect(worker.send(:rules)).to eq link_check_rule
    end
  end
end
