# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe LinkCheckJob do
  let(:link_check_job) { FactoryBot.build(:link_check_job, url: "http://google.co.nz") }

  describe 'validations' do
    it 'should validates the presence of url' do
      link_check_job.url = nil
      link_check_job.should_not be_valid
    end

    it 'should validates the presence of record_id' do
      link_check_job.record_id = nil
      link_check_job.should_not be_valid
    end

    it 'should validate the presence of source_id' do
      link_check_job.source_id = nil
      link_check_job.should_not be_valid
    end
  end

  describe 'after:create' do
    after { link_check_job.save }

    it 'should call enqueue' do
      link_check_job.should_receive(:enqueue)
    end
  end

  describe '#enqueue' do
    it 'enqueues a job' do
      LinkCheckWorker.should_receive(:perform_async).with(link_check_job.id.to_s)
      link_check_job.send(:enqueue)
    end

    it 'should not enqueue a job if link checking is disabled' do
      ENV['LINK_CHECKING_ENABLED'] = nil
      LinkCheckWorker.should_not_receive(:perform_async).with(link_check_job.id.to_s)
      link_check_job.send(:enqueue)
    end
  end
end
