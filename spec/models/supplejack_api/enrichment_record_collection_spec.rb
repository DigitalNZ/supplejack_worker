# frozen_string_literal: true

require 'rails_helper'

describe SupplejackApi::EnrichmentRecordCollection do
  describe '#initialize' do
    context 'when records & meta exists' do
      let(:mock_record_response) { { 'records' => [], 'meta' => {} } }
      let(:subject) { described_class.new(mock_record_response) }

      it 'has elements' do
        expect(subject.elements).to eq mock_record_response['records']
      end

      it 'has pagination' do
        expect(subject.pagination).to eq mock_record_response['meta']
      end
    end

    context 'when records & meta does not exist' do
      let(:subject) { described_class.new }

      it 'has empty elements' do
        expect(subject.elements).to eq []
      end

      it 'has default pagination' do
        expect(subject.pagination).to eq({ page: 1, total_pages: 1 })
      end
    end
  end
end
