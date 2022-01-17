# frozen_string_literal: true

require 'rails_helper'

describe PreviewsController do
  describe 'POST create' do
    it 'spawns a preview worker' do
      expect(PreviewStartJob).to receive(:perform_later).with('123')

      post :create, params: { preview: { id: '123' } }
    end
  end
end
