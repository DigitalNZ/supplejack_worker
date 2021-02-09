# frozen_string_literal: true
require 'rails_helper'

RSpec.describe State do
  let(:stateful_job) { create(:harvest_job, :stateful) }
  let(:state) { stateful_job.states.first }

  describe '#attributes' do
    it 'has the page number' do
      expect(state.page).to eq 1
    end

    it 'has the per_page count' do
      expect(state.per_page).to eq 10
    end

    it 'has the limit' do
      expect(state.limit).to eq 100
    end

    it 'has the counter' do
      expect(state.counter).to eq 1
    end

    it 'has the base_urls' do
      expect(state.base_urls).to eq []
    end

    it 'has the total_selector' do
      expect(state.total_selector).to eq '$.totalObjects'
    end
  end
end
