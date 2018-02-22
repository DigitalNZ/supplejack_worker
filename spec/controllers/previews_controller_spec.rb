# frozen_string_literal: true
require 'rails_helper'

describe PreviewsController do
  let(:preview) { create(:preview, id: '123') }
  let(:user) { create(:user, id: '1234') }

  describe 'POST create' do
    let(:preview) { double(:preview) }
    before { Preview.stub(:spawn_preview_worker) { 'abc123' } }

    it 'spawns a preview worker' do
      Preview.should_receive(:spawn_preview_worker).with('id' => '123', 'harvest_job' => { 'parser_code' => 'CODE', 'index' => '1000' })
      post :create, params: { preview: { id: '123', harvest_job: { parser_code: 'CODE', index: 1000 } } }
    end
  end

  describe 'GET show' do
    it 'should find the preview object' do
      Preview.should_receive(:find).with(preview.id.to_s) { preview }
      get :show, params: { id: preview.id }
      assigns(:preview).should eq preview
    end
  end
end
