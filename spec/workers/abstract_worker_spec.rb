# frozen_string_literal: true
require 'rails_helper'

describe AbstractWorker do
  let(:worker) { AbstractWorker.new }
  let(:job) { create(:harvest_job) }

  before { allow(AbstractJob).to receive(:find) { job } }

  describe '#stop_harvest?' do
    before { allow(job).to receive(:enqueue_enrichment_jobs) { nil } }

    context 'status is stopped' do
      let(:job) { create(:harvest_job, status: 'stopped') }

      it 'returns true' do
        expect(worker.stop_harvest?).to be_truthy
      end

      it 'returns true true when errors over limit' do
        allow(job).to receive(:errors_over_limit?) { true }
        expect(worker.stop_harvest?).to be_truthy
      end
    end

    context 'status is finished' do
      let(:job) { create(:harvest_job, status: 'finished') }

      it 'returns true' do
        expect(worker.stop_harvest?).to be_truthy
      end

      it 'should not finsihed the job (again)' do
        expect(job).not_to receive(:finish!)
        worker.stop_harvest?
      end
    end

    context 'status is active' do
      let(:job) { create(:harvest_job, status: 'active') }

      it 'returns true when errors over limit' do
        allow(job).to receive(:errors_over_limit?) { true }
        expect(worker.stop_harvest?).to be_truthy
      end

      it 'returns false' do
        expect(worker.stop_harvest?).to be_falsey
      end
    end
  end

  describe '#api_update_finished?' do
    it 'should return true if the api update is finished' do
      allow(job).to receive(:posted_records_count) { 100 }
      allow(job).to receive(:records_count) { 100 }
      expect(worker.send(:api_update_finished?)).to be_truthy
    end

    it 'should return false if the api update is not finished' do
      allow(job).to receive(:posted_records_count) { 10 }
      allow(job).to receive(:records_count) { 100 }
      expect(worker.send(:api_update_finished?)).to be_falsey
    end

    it 'should reload the enrichment job' do
      expect(job).to receive(:reload)
      worker.send(:api_update_finished?)
    end
  end

  describe '#sanitize_id' do
    it 'accepts strings and returns the string' do
      expect(worker.send(:sanitize_id, 'abc')).to eq 'abc'
    end

    it 'it accepts serialized object_ids and returns the id string' do
      expect(worker.send(:sanitize_id, '$oid' => 'preview123')).to eq 'preview123'
    end
  end

  describe '#job' do
    it 'should find the job' do
      worker.instance_variable_set(:@job_id, 123)
      expect(AbstractJob).to receive(:find).with('123') { job }
      expect(worker.job).to eq job
    end

    it 'memoizes the result' do
      expect(AbstractJob).to receive(:find).once
      worker.job
      worker.job
    end
  end
end
