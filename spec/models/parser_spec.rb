# frozen_string_literal: true
require 'rails_helper'

describe Parser do
  let(:parser) { Parser.new(name: 'Europeana') }

  describe '#load_file' do
    let!(:loader) { double(:loader).as_null_object }

    before(:each) do
      allow(parser).to receive(:loader).and_return loader
    end

    it 'initializes a loader object' do
      expect(SupplejackCommon::Loader).to receive(:new).with(parser, :staging)
      parser.load_file(:staging)
    end

    it 'loads the parser file' do
      expect(loader).to receive(:load_parser)
      parser.load_file(:staging)
    end
  end
end
