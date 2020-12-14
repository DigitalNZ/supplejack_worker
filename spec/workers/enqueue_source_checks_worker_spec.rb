# frozen_string_literal: true

require 'rails_helper'

describe EnqueueSourceChecksWorker do
  let(:worker) { EnqueueSourceChecksWorker.new }

  let(:link_check_rules) do
    [double(:link_check_rule, source_id: '1', active: true),
     double(:link_check_rule, source_id: '2', active: true),
     double(:link_check_rule, source_id: '3', active: false)]
  end

  before { allow(LinkCheckRule).to receive(:all) { link_check_rules } }

  describe '#perform' do
    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'should enqueue a source check worker for each source to check' do
      worker.perform
      %w[1 2].each do |source|
        expect(SourceCheckWorker).to have_enqueued_sidekiq_job(source)
      end
    end
  end

  describe '.sources_to_check' do
    it 'should get all the sources to check' do
      expect(EnqueueSourceChecksWorker.sources_to_check).to include('1', '2')
    end

    it 'should not include inactive sources' do
      expect(EnqueueSourceChecksWorker.sources_to_check).not_to include('3')
    end
  end
end
