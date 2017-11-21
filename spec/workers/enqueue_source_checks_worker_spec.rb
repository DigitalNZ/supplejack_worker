# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe EnqueueSourceChecksWorker do
  let(:worker) { EnqueueSourceChecksWorker.new }

  let(:link_check_rules) do
    [double(:link_check_rule, source_id: '1', active: true),
     double(:link_check_rule, source_id: '2', active: true),
     double(:link_check_rule, source_id: '3', active: false)]
  end

  before { LinkCheckRule.stub(:all) { link_check_rules } }

  describe '#perform' do
    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'should enqueue a source check worker for each source to check' do
      worker.perform
      ["1", "2"].each do |source|
        expect(SourceCheckWorker).to have_enqueued_sidekiq_job(source)
      end
    end
  end

  describe '.sources_to_check' do
    it 'should get all the sources to check' do
      EnqueueSourceChecksWorker.sources_to_check.should include('1', '2')
    end

    it 'should not include inactive sources' do
      EnqueueSourceChecksWorker.sources_to_check.should_not include('3')
    end
  end
end
