# frozen_string_literal: true
require 'rails_helper'

describe ParserVersion do
  let(:parser) { Parser.new(name: 'Europeana', id: '123', data_type: 'Record', source: source) }
  let(:parser_version) { ParserVersion.new(parser_id: '123') }
  let(:job) { mock_model(HarvestJob).as_null_object }
  let(:source) { Source.new(name: 'source_name') }

  describe '#last_harvested_at' do
    let!(:time) { Time.now }
    let!(:job1) { create(:harvest_job, start_time: time - 1.day, parser_id: '12', status: 'finished') }
    let!(:job2) { create(:harvest_job, start_time: time - 2.day, parser_id: '12', status: 'finished') }

    it 'should return the last date a harvest job was run' do
      Timecop.freeze(time) do
        parser = Parser.new(id: '12', name: 'Europeana')
        parser.last_harvested_at.to_i.should eq (time - 1.day).to_i
      end
    end

    it 'should return nil when no job has been run' do
      parser = Parser.new(id: '123', name: 'Europeana')
      parser.last_harvested_at.should be_nil
    end
  end

  describe '#harvest_jobs' do
    it 'finds all the harvest jobs using this parser' do
      HarvestJob.should_receive(:where).with(parser_id: parser_version.parser_id) { job }
      parser_version.harvest_jobs
    end

    it 'finds all the harvest jobs with specified status' do
      HarvestJob.should_receive(:where).with(parser_id: parser_version.parser_id, status: 'finished') { job }
      parser_version.harvest_jobs('finished')
    end
  end

  describe '#source' do
    RSpec.configure { |c| c.include ActiveResourceMockHelper }

    it 'finds parser thru active resource and return its source' do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get '/parsers/123.json', required_headers, parser.to_json
      end
      expect(parser_version.source).to eq parser.source
    end
  end
end
