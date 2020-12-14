# frozen_string_literal: true

require 'rails_helper'

describe PreviewsController do
  let(:preview) { create(:preview, id: '123') }
  let(:user) { create(:user, id: '1234') }

  describe 'POST create' do
    let(:preview) { double(:preview) }
    before { allow(Preview).to receive(:spawn_preview_worker).and_return('abc123') }

    it 'spawns a preview worker' do
      allow(Preview).to receive(:spawn_preview_worker).with('id' => '123', 'harvest_job' => { 'parser_code' => 'CODE', 'index' => '1000' })
      post :create, params: { preview: { id: '123', harvest_job: { parser_code: 'CODE', index: 1000 } } }
    end
  end

  describe 'GET show' do
    it 'should find the preview object' do
      allow(Preview).to receive(:find).with(preview.id.to_s).and_return(preview)
      get :show, params: { id: preview.id }
      expect(assigns(:preview)).to eq preview
    end
  end
end
