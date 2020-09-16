# frozen_string_literal: true
require 'rails_helper'

RSpec.describe JobState do
  let(:job_state) { create(:job_state) }

  describe '#attributes' do
    it 'has a start time' do
      expect(job_state.created_at).not_to be(nil)
    end

    it 'has the url associated with this state' do
      expect(job_state.url).to eq 'http://google.com'
    end
  end
end