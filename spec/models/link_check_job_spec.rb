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
