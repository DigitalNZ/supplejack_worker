# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Supplejack::HarvestError do
  describe '#initiliaze' do
    let(:error) { described_class.new('message', 'backtrace', 'raw_data', 1) }
    it 'can be initialized with a message' do
      expect(error.message).to eq 'message'
    end

    it 'can be initialized with a backtrace' do
      expect(error.backtrace).to eq 'backtrace'
    end

    it 'can be initialized with raw data' do
      expect(error.raw_data).to eq 'raw_data'
    end

    it 'can be initialized with a parser id' do
      expect(error.parser_id).to eq '1'
    end
  end
end
