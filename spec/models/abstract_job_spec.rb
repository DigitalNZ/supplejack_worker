# frozen_string_literal: true

require 'rails_helper'

describe AbstractJob do
  let(:job) { create(:abstract_job, parser_id: '12345', version_id: '666') }

  describe '.search' do
    let!(:active_job) { create(:abstract_job, status: 'active') }

    it 'returns all active harvest jobs' do
      create(:abstract_job, status: 'finished')
      expect(AbstractJob.search('status' => 'active')).to eq [active_job]
    end

    it 'paginates through the records' do
      expect(AbstractJob).to receive(:page).with(2).and_return(AbstractJob.unscoped)
      AbstractJob.search('status' => 'active', 'page' => '2').to_a
    end

    it 'returns the recent harvest jobs first' do
      active_job2 = create(:abstract_job, status: 'active', start_time: Time.now + 5.seconds)
      expect(AbstractJob.search('status' => 'active').first).to eq active_job2
    end

    it 'returns only test harvest jobs of a specific parser' do
      job2 = create(:abstract_job, parser_id: '333', environment: 'test')
      abstract_job_search = AbstractJob.search('parser_id' => '333', 'environment' => 'test')
      expect(abstract_job_search).to eq [job2]
    end

    it 'limits the number of harvest jobs returned' do
      create(:abstract_job, parser_id: '333', environment: 'test', start_time: Time.now + 5.seconds)
      abstract_job_results = AbstractJob.search('limit' => '1').to_a.size
      expect(abstract_job_results).to eq 1
    end

    it 'finds all harvest jobs either in staging or production' do
      job1 = create(:abstract_job, parser_id: '333', environment: 'staging', start_time: Time.now)
      job2 = create(:abstract_job, parser_id: '334', environment: 'production', start_time: Time.now + 2.seconds)
      jobs = AbstractJob.search('environment' => %w[staging production]).to_a
      expect(jobs).to include job1, job2
    end
  end

  describe '.clear_raw_data' do
    it 'fetches harvest jobs older than a week' do
      expect(AbstractJob).to receive(:disposable).and_return([job])
      expect(job).to receive(:clear_raw_data)
      AbstractJob.clear_raw_data
    end
  end

  describe 'disposable' do
    let!(:disposable_job) { create(:abstract_job, created_at: 4.months.ago) }
    let!(:important_job)  { create(:abstract_job) }

    it 'returns jobs that are more than 3 months old' do
      expect(AbstractJob.disposable).to include disposable_job
    end

    it 'does not return jobs that are less than 3 months old' do
      expect(AbstractJob.disposable).not_to include important_job
    end
  end

  describe '#parser' do
    let!(:version) { mock_model(ParserVersion).as_null_object }

    it 'returns @parser if @parser is set' do
      job.instance_variable_set(:@parser, 'a parser!')
      expect(job.parser).to eq 'a parser!'
    end

    context 'with version_id' do
      it 'finds the parser by id' do
        expect(ParserVersion).to receive(:find).with('666', params: { parser_id: '12345' })
        job.parser
      end
    end

    context 'without version_id' do
      before(:each) do
        job.version_id = ''
        job.environment = 'staging'
      end

      it 'finds the current parser version for the environment' do
        expect(ParserVersion).to receive(:find).with(:one, from: :current, params: { parser_id: '12345', environment: 'staging' }).and_return(version)
        job.parser
      end

      it 'should set the version_id of the fetched version' do
        expect(ParserVersion).to receive(:find).and_return(mock_model(ParserVersion, id: '888').as_null_object)
        job.parser
        expect(job.version_id).to eq '888'
      end

      context 'the environment is preview and parser_code is present' do
        let(:parser) { double(:parser).as_null_object }
        before(:each) do
          job.environment = 'preview'
          job.parser_code = 'new code'
          allow(Parser).to receive(:find).and_return(parser)
        end

        it 'finds the parser by id' do
          expect(Parser).to receive(:find).with('12345')
          job.parser
        end

        it 'sets the parser content to parser_code' do
          expect(parser).to receive(:content=).with('new code')
          job.parser
        end
      end
    end

    context 'without version_id and environment' do
      before do
        job.version_id = ''
        job.environment = nil
      end

      it 'finds the parser by id' do
        expect(Parser).to receive(:find).with('12345')
        job.parser
      end
    end
  end

  describe '#required_enrichments' do
    it 'returns an array of enrichments with required: true' do
      allow(job).to receive_message_chain(:parser, :enrichment_definitions).and_return(ndha_rights: { required_for_active_record: true },
thumbnails: {})
      expect(job.required_enrichments).to eq [:ndha_rights]
    end
  end

  describe 'status' do
    describe 'initial' do
      it 'sets the initial status to active' do
        expect(job.ready?).to be_truthy
      end
    end

    describe 'start!' do
      it 'sets the start time to now' do
        time = Time.now
        Timecop.freeze(time) do
          job.start!
          expect(job.start_time.to_i).to eq time.to_i
        end
      end

      it 'sets the status to active' do
        job.start!
        expect(job.active?).to be_truthy
      end

      it 'sets the records count to 0' do
        job.start!
        expect(job.records_count).to eq 0
      end

      it 'sets the processed count to 0' do
        job.start!
        expect(job.processed_count).to eq 0
      end

      it 'saves the job' do
        expect(job).to receive(:save)
        job.start!
      end
    end

    describe 'finish!' do
      it 'sets the status to finished' do
        job.finish!
        expect(job.finished?).to be_truthy
      end

      it 'sets the end time to now' do
        time = Time.now
        Timecop.freeze(time) do
          job.finish!
          expect(job.end_time.to_i).to eq time.to_i
        end
      end

      it 'sets the throughput' do
        expect(job).to receive(:calculate_throughput)
        job.finish!
      end

      it 'sets the errors count' do
        expect(job).to receive(:calculate_errors_count)
        job.finish!
      end

      it 'saves the job' do
        expect(job).to receive(:save)
        job.finish!
      end
    end

    describe 'error!' do
      it 'sets the status to failed' do
        job.error!
        expect(job.failed?).to be_truthy
      end

      context 'start time' do
        it 'should set the start time to now if not set' do
          time = Time.now
          Timecop.freeze(time) do
            job.error!
            expect(job.end_time.to_i).to eq time.to_i
          end
        end

        it 'does not set the start time to now if set' do
          Timecop.freeze(Time.now - 1.hour) do
            job.start!
          end

          time = Time.now
          Timecop.freeze(time) do
            job.error!
            expect(job.reload.start_time.to_i).to_not eq time.to_i
          end
        end
      end

      it 'sets the end time to now' do
        job.start!
        time = Time.now
        Timecop.freeze(time) do
          job.error!
          expect(job.end_time.to_i).to eq time.to_i
        end
      end

      it 'sets the errors count' do
        expect(job).to receive(:calculate_errors_count)
        job.error!
      end

      it 'saves the job' do
        expect(job).to receive(:save)
        job.error!
      end
    end

    describe 'stop!' do
      before(:each) do
        job.start!
      end

      it 'sets the status to failed' do
        job.stop!
        expect(job.stopped?).to be_truthy
      end

      it 'sets the end time to now' do
        time = Time.now
        Timecop.freeze(time) do
          job.stop!
          expect(job.end_time.to_i).to eq time.to_i
        end
      end

      it 'saves the job' do
        expect(job).to receive(:save)
        job.stop!
      end
    end
  end

  describe 'resume!' do
    let(:resumable_job) { create(:abstract_job, parser_id: '12345', version_id: '666', posted_records_count: 10, records_count: 12) }

    it 'sets the records_count to be the same as the posted_records_count' do
      resumable_job.resume!
      expect(resumable_job.records_count).to eq resumable_job.posted_records_count
    end

    it 'sets the job status to be active' do
      resumable_job.resume!
      expect(resumable_job.active?).to eq true
    end

    it 'saves the job' do
      expect(resumable_job).to receive(:save)
      resumable_job.resume!
    end
  end

  describe 'test?' do
    it 'returns true' do
      job.environment = 'test'
      expect(job.test?).to be_truthy
    end

    it 'returns false' do
      job.environment = 'staging'
      expect(job.test?).to be_falsey
    end
  end

  describe '#preview?' do
    it 'returns true' do
      job.environment = 'preview'
      expect(job.preview?).to be_truthy
    end

    it 'returns false' do
      job.environment = 'staging'
      expect(job.preview?).to be_falsey
    end
  end

  describe 'calculate_throughput' do
    before(:each) do
      job.end_time = Time.now
      job.status = 'finished'
    end

    it 'calculates the average record time' do
      job.records_count = 100
      allow(job).to receive(:duration).and_return(100)
      job.calculate_throughput
      expect(job.throughput).to eq 1.0
    end

    it 'returns 0 when records harvested is 0' do
      job.records_count = 0
      allow(job).to receive(:duration).and_return(100)
      job.calculate_throughput
      expect(job.throughput).to eq 0
    end

    it 'should not return NaN' do
      job.records_count = 0
      allow(job).to receive(:duration).and_return(0.0)
      job.calculate_throughput
      expect(job.throughput).to be_nil
    end
  end

  describe '.jobs_since' do
    let!(:finished_job) { create(:abstract_job, status: 'finished', start_time: (DateTime.now - 1), environment: 'staging') }

    it 'returns a count of harvest jobs in the last 2 days' do
      create(:abstract_job, status: 'finished', start_time: (DateTime.now - 3), environment: 'staging')
      since = DateTime.now - 2
      jobs_since = AbstractJob.jobs_since('datetime' => since.to_s, 'environment' => 'staging', 'status' => 'finished')
      expect(jobs_since).to eq [finished_job]
    end
  end

  describe '#duration' do
    let!(:time) { Time.now }

    it 'returns the duration in seconds' do
      job.start_time = time - 10.seconds
      job.end_time = time
      job.save
      job.reload
      expect(job.duration).to eq 10.0
    end

    it 'returns nil start_time is nil' do
      job.start_time = nil
      expect(job.duration).to be_nil
    end

    it 'returns nil end_time is nil' do
      job.end_time = nil
      expect(job.duration).to be_nil
    end

    it 'returns the proper duration' do
      time = Time.now
      Timecop.freeze(time) do
        job = create(:abstract_job, start_time: time)
        job.end_time = Time.now + 5.seconds
        expect(job.duration).to eq 5
      end
    end
  end

  describe 'total_errors_count' do
    it 'returns a sum of failed and invalid records' do
      allow(job).to receive(:invalid_records).and_return(double(:array, count: 10))
      allow(job).to receive(:failed_records).and_return(double(:array, count: 20))
      expect(job.total_errors_count).to eq 30
    end
  end

  describe '#errors_over_limit?' do
    context 'errors count over 100' do
      before { allow(job).to receive(:total_errors_count).and_return(101) }

      it 'returns true' do
        expect(job.errors_over_limit?).to be_truthy
      end
    end

    context 'errors count under 100' do
      before { allow(job).to receive(:total_errors_count).and_return(99) }

      it 'returns false' do
        expect(job.errors_over_limit?).to be_falsey
      end
    end
  end

  describe '#clear_raw_data' do
    it 'removes invalid records' do
      job.invalid_records.create(raw_data: 'Wrong', errors_messages: [])
      job.clear_raw_data
      job.reload
      expect(job.invalid_records.count).to eq 0
    end

    it 'removes failed records' do
      job.failed_records.create(message: 'Hi')
      job.clear_raw_data
      job.reload
      expect(job.failed_records.count).to eq 0
    end
  end

  describe '#increment_records_count!' do
    it 'increments the records count' do
      job.increment_records_count!
      job.reload
      expect(job.records_count).to eq 1
    end
  end

  describe '#increment_processed_count!' do
    it 'increments the records count' do
      job.increment_processed_count!
      job.reload
      expect(job.processed_count).to eq 1
    end
  end
end
