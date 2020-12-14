# frozen_string_literal: true

require 'rails_helper'

describe Preview do
  let(:preview_attributes) { { harvest_job: { user_id: 20, environment: 'preview', index: 150, parser_id: 'abc123', parser_code: 'code' } } }
  let(:job) { HarvestJob.new(environment: 'preview', index: 1, harvest_failure: {}) }
  let(:preview) { build(:preview, id: 'abc123') }

  describe '.spawn_preview_worker' do
    before do
      allow(HarvestJob).to receive(:create).and_return job
      allow(Preview).to    receive(:create).and_return preview
      allow(job).to        receive(:valid?).and_return true
    end

    it 'creates a preview object' do
      expect(Preview).to receive(:create)
      Preview.spawn_preview_worker(preview_attributes)
    end

    it 'creates a harvest job' do
      expect(HarvestJob).to receive(:create).with(preview_attributes[:harvest_job]).and_return job
      Preview.spawn_preview_worker(preview_attributes)
    end

    it 'enqueues the job' do
      Preview.spawn_preview_worker(preview_attributes)
      expect(PreviewWorker).to have_enqueued_sidekiq_job(job.id.to_s, preview.id)
    end

    it 'returns the preview_id' do
      spawn_worker_response = Preview.spawn_preview_worker(preview_attributes)
      expect(spawn_worker_response).to eq preview
    end

    context 'harvest_failure' do
      let(:running_job) { HarvestJob.new(environment: 'preview', index: 1, harvest_failure: {}, status: 'active', parser_id: 'abc123') }

      before do
        allow(job).to        receive(:valid?).and_return false
        allow(job).to        receive(:harvest_failure).and_return Hash.new
        allow(Preview).to    receive(:find).and_return preview
        allow(preview).to    receive(:update_attribute)
        allow(HarvestJob).to receive(:where).and_return [running_job]
        allow(job).to        receive(:save!)
      end

      it 'stops the currently active job' do
        expect(HarvestJob).to receive(:where).with(status: 'active', parser_id: job.parser_id, environment: 'preview') { [running_job] }
        expect(running_job).to receive(:stop!)
        Preview.spawn_preview_worker(preview_attributes)
      end

      it 'resaves the current running job' do
        expect(job).to receive(:save!)
        Preview.spawn_preview_worker(preview_attributes)
      end
    end
  end
end
