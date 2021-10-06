# frozen_string_literal: true

require 'rails_helper'

describe ParserVersion do
  let(:parser) { Parser.new(name: 'Europeana', id: '123', data_type: 'Record', source: source) }
  let(:parser_version) { ParserVersion.new(parser_id: '123') }
  let(:parser_version_no_job) { ParserVersion.new(parser_id: '1') }
  let(:job) { mock_model(HarvestJob).as_null_object }
  let(:source) { Source.new(source_id: 'source_name') }

  describe '#last_harvested_at' do
    let!(:time) { Time.now }
    let!(:job2) { create(:harvest_job, start_time: time - 2.day, parser_id: '123', status: 'finished') }
    let!(:job1) { create(:harvest_job, start_time: time - 1.day, parser_id: '123', status: 'finished') }

    it 'returns the last date a harvest job was run' do
      Timecop.freeze(time) do
        expect(parser_version.last_harvested_at.to_i).to eq job1.start_time.to_i
      end
    end

    it 'ignores preview jobs' do
      preview_job = create(:harvest_job, start_time: time, parser_id: '123', status: 'finished', environment: 'preview')

      last_finished_harvest_job = HarvestJob.desc(:start_time)
        .find_by(parser_id: '123', status: 'finished')

      expect(last_finished_harvest_job).to eq preview_job

      Timecop.freeze(time) do
        expect(parser_version.last_harvested_at.to_i).not_to eq preview_job.start_time.to_i
      end
    end

    it 'returns nil when no job has been run' do
      expect(parser_version_no_job.last_harvested_at).to be_nil
    end
  end

  describe '#source' do
    it 'finds parser through active resource and return its source' do
      allow(Parser).to receive(:find).and_return(parser)
      expect(parser_version.source).to eq parser.source
    end
  end
end
