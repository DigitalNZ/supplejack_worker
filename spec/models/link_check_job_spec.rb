# frozen_string_literal: true

require 'rails_helper'

describe LinkCheckJob do
  let(:link_check_job) { build(:link_check_job, url: 'http://google.co.nz') }

  before { ENV['LINK_CHECKING_ENABLED'] = 'true' }

  describe 'validations' do
    it 'validates the presence of url' do
      link_check_job.url = nil
      expect(link_check_job).to_not be_valid
    end

    it 'validatess the presence of record_id' do
      link_check_job.record_id = nil
      expect(link_check_job).to_not be_valid
    end

    it 'validates the presence of source_id' do
      link_check_job.source_id = nil
      expect(link_check_job).to_not be_valid
    end

    describe 'validates if already_checked?' do
      let(:new_job) { create(:link_check_job, url: 'http://google.co.nz') }

      context 'when job with same id already exists' do
        context 'when it was created before 6 hours' do
          before do
            allow(new_job).to receive(:created_at).and_return(DateTime.now.in_time_zone - 1.day)
            allow(LinkCheckJob).to receive(:where).and_return([new_job])
          end

          it 'succeed' do
            job = build(:link_check_job, url: 'http://google.co.nz', record_id: new_job.record_id)

            expect(job).to be_valid
          end
        end

        context 'when it was created with in last 6 hours' do
          it 'fails' do
            job = build(:link_check_job, url: 'http://google.co.nz', record_id: new_job.record_id)

            expect(job).to_not be_valid
            expect(job.errors[:record_id]).to eq [I18n.t('link_check_job.error', record_id: job.record_id, check_interval: 6)]
          end
        end
      end
    end
  end

  describe 'after:create' do
    after { link_check_job.save }

    it 'calls enqueue' do
      expect(link_check_job).to receive(:enqueue)
    end
  end

  describe '#enqueue' do
    it 'enqueues a job' do
      expect(LinkCheckWorker).to receive(:perform_async).with(link_check_job.id.to_s)
      link_check_job.send(:enqueue)
    end

    it 'does not enqueue a job if link checking is disabled' do
      ENV['LINK_CHECKING_ENABLED'] = nil
      expect(LinkCheckWorker).to_not receive(:perform_async).with(link_check_job.id.to_s)
      link_check_job.send(:enqueue)
    end
  end

  describe '#source' do
    it 'calls source find' do
      expect(Source).to receive(:find).with(link_check_job.source_id)

      link_check_job.source
    end
  end
end
