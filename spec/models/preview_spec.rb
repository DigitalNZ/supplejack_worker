# frozen_string_literal: true

require 'rails_helper'

describe Preview do
  let(:job) { HarvestJob.new(environment: 'preview', index: 1, harvest_failure: {}) }
  let(:preview) { build(:preview, _id: 'abc123') }

  before { allow(preview).to receive(:update_attributes) }

  describe '.spawn_preview_worker' do
    before do
      allow(HarvestJob).to receive(:create).and_return job
      allow(Preview).to    receive(:create).and_return preview
      allow(job).to        receive(:valid?).and_return true
    end


    it 'creates a harvest job' do
      expect(HarvestJob).to receive(:create)
                            .with({ environment: 'preview',
                                    index: preview.index,
                                    limit: preview.index + 1,
                                    parser_code: preview.parser_code,
                                    parser_id: preview.parser_id,
                                    user_id: preview.user_id })
                            .and_return job

      preview.spawn_preview_worker
    end

    it 'enqueues the job' do
      preview.spawn_preview_worker

      expect(PreviewWorker).to have_enqueued_sidekiq_job(job.id.to_s, preview.id)
    end

    it 'returns the preview_id' do
      spawn_worker_response = preview.spawn_preview_worker

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

        preview.spawn_preview_worker
      end

      it 'resaves the current running job' do
        expect(job).to receive(:save!)

        preview.spawn_preview_worker
      end
    end
  end
end
