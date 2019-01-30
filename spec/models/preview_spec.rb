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

  describe 'harvested_attributes_json' do
    before { allow(preview).to receive(:harvested_attributes) { '{"title": "Json!"}' } }

    it 'returns the json in a pretty format' do
      expect(preview.send(:harvested_attributes_json)).to eq JSON.pretty_generate(
        'title': 'Json!'
      )
    end
  end

  describe '#api_record_output' do
    let(:attributes_json) { JSON.pretty_generate('title': 'Json!') }

    before do
      allow(preview).to receive(:api_record_json) { attributes_json }
    end

    it 'returns highlighted json' do
      output = %q{{\n  <span class=\"key\"><span class=\"delimiter\">&quot;</span><span class=\"content\">title</span><span class=\"delimiter\">&quot;</span></span>: <span class=\"string\"><span class=\"delimiter\">&quot;</span><span class=\"content\">Json!</span><span class=\"delimiter\">&quot;</span></span>\n}}
      expect(preview.api_record_output).to match(output)
    end
  end

  describe '#raw_output' do
    before { allow(preview).to receive(:raw_data) }

    it 'should call pretty_xml_output when format is xml' do
      preview.format = 'xml'
      expect(preview).to receive(:pretty_xml_output) {}
      preview.raw_output
    end

    it 'should call pretty_json_output when format is not xml' do
      preview.format = 'json'
      expect(preview).to receive(:pretty_json_output) {}
      preview.raw_output
    end
  end

  describe '#pretty_xml_output' do
    it 'returns the raw data' do
      allow(preview).to receive(:raw_data) { 'I am raw!' }
      expect(preview.pretty_xml_output).to eq 'I am raw!'
    end
  end

  describe 'pretty_json_output' do
    before { allow(preview).to receive(:raw_data) { '{ "title": "Json!" }' } }

    it 'returns the json in a pretty format' do
      expect(preview.send(:pretty_json_output)).to eq JSON.pretty_generate(
        'title': 'Json!'
      )
    end
  end

  describe '#field_errors_json' do
    it 'returns the json in a pretty format' do
      allow(preview).to receive(:field_errors) { '{"title":"WRONG!"}' }
      expect(preview.field_errors_json).to eq JSON.pretty_generate(
        'title': 'WRONG!'
      )
    end

    it 'returns nil when there are no field_errors' do
      allow(preview).to receive(:field_errors)
      expect(preview.field_errors_json).to be nil
    end
  end

  describe '#field_errors?' do
    it 'returns false when there are no field_errors' do
      allow(preview).to receive(:field_errors)
      expect(preview.field_errors?).to be nil
    end

    it 'returns true when there are field_errors' do
      allow(preview).to receive(:field_errors) { '{ "title":"Invalid" }' }
      expect(preview.field_errors?).to be true
    end
  end

  describe '#field_errors_output' do
    let(:field_errors_json) { JSON.pretty_generate('title': 'Invalid!') }

    before do
      allow(preview).to receive(:field_errors?) { true }
      allow(preview).to receive(:field_errors_json) { field_errors_json }
    end

    it 'returns highlighted json' do
      output = %q{{\n  <span class=\"key\"><span class=\"delimiter\">&quot;</span><span class=\"content\">title</span><span class=\"delimiter\">&quot;</span></span>: <span class=\"string\"><span class=\"delimiter\">&quot;</span><span class=\"content\">Invalid!</span><span class=\"delimiter\">&quot;</span></span>\n}}
      expect(preview.field_errors_output).to match(output)
    end

    it 'returns nil when there are no field_errors' do
      allow(preview).to receive(:field_errors?) { false }
      expect(preview.field_errors_output).to be nil
    end
  end

  describe '#harvested_attributes_output' do
    let(:attributes_json) { JSON.pretty_generate('title': 'Json!') }

    before do
      allow(preview).to receive(:harvested_attributes_json) { attributes_json }
    end

    it 'returns highlighted json' do
      output = %q{{\n  <span class=\"key\"><span class=\"delimiter\">&quot;</span><span class=\"content\">title</span><span class=\"delimiter\">&quot;</span></span>: <span class=\"string\"><span class=\"delimiter\">&quot;</span><span class=\"content\">Json!</span><span class=\"delimiter\">&quot;</span></span>\n}}
      expect(preview.harvested_attributes_output).to match(output)
    end
  end
end
