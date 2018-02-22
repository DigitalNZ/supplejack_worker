# frozen_string_literal: true
require 'rails_helper'

describe Parser do
  let(:parser) { Parser.new(name: 'Europeana') }

  describe '#load_file' do
    let!(:loader) { double(:loader).as_null_object }

    before(:each) do
      parser.stub(:loader) { loader }
    end

    it 'should initialize a loader object' do
      SupplejackCommon::Loader.should_receive(:new).with(parser, :staging)
      parser.load_file(:staging)
    end

    it 'should load the parser file' do
      loader.should_receive(:load_parser)
      parser.load_file(:staging)
    end
  end

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
end
