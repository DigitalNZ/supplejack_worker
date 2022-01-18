# frozen_string_literal: true

require 'rails_helper'

describe PreviewsController do
  describe 'POST create' do
    it 'spawns a preview worker' do
      expect(PreviewWorker).to receive(:perform_async).with('job_id', 'preview_id')

      post :create, params: { preview_id: 'preview_id', job_id: 'job_id' }
    end
  end
end
