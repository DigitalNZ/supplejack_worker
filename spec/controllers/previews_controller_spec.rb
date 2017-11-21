# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe PreviewsController do
  let(:preview) { create(:preview, id: '123') }
  let(:user) { create(:user, id: '1234') }

  let(:preview) { create(:preview, id: '123') }
  let(:user) { create(:user, id: '1234') }

  describe 'POST create' do
    let(:preview) { double(:preview) }
    before { Preview.stub(:spawn_preview_worker) { 'abc123' } }

    it 'spawns a preview worker' do
      Preview.should_receive(:spawn_preview_worker).with('id' => '123', 'harvest_job' => {'parser_code' => 'CODE', 'index' => '1000'})
      post :create, params: { preview: { id: '123', harvest_job: {parser_code: 'CODE', index: 1000} } }
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