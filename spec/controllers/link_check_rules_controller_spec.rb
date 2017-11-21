# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe LinkCheckRulesController do
  let(:link_check_rule) { create(:link_check_rule) }
  let(:user) { create(:user) }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
    controller.stub(:current_user) { user }
  end

  describe 'GET index' do
    it 'should get all of the collection rules' do
      LinkCheckRule.should_receive(:all) { [link_check_rule] }
      get :index, params: {}, format: 'json'
      assigns(:link_check_rules).should eq [link_check_rule]
    end

    it 'should do a where if link_check_rule is defined' do
      params = { link_check_rule: { collection_title: 'link_check_rule' } }
      LinkCheckRule.should_receive(:where).with(params[:link_check_rule].stringify_keys)
      get :index, params: params, format: 'json'
    end
  end

  describe 'GET show' do
    it 'should get the collection rule' do
      LinkCheckRule.should_receive(:find) { link_check_rule }
      get :show, params: { id: link_check_rule.id }
      assigns(:link_check_rule).should eq link_check_rule
    end
  end

  describe 'POST create' do
    it 'should make a new collection rule and assign it' do
      params = ActionController::Parameters.new('collection_title' => 'collection_title', 'status_codes' => '203,205', source_id: 'source_id').permit!
      LinkCheckRule.should_receive(:create!).with(params) { link_check_rule }
      post :create, params: { link_check_rule: { collection_title: 'collection_title', status_codes: '203,205', source_id: 'source_id' } }
      assigns(:link_check_rule) { link_check_rule }
    end
  end

  describe 'PUT update' do
    it 'should find the link_check_rule' do
      LinkCheckRule.should_receive(:find) { link_check_rule }
      put :update, params: { id: link_check_rule.id, link_check_rule: { collection_title: 'collection_title', status_codes: '203,205' } }
      assigns(:link_check_rule) { link_check_rule }
    end

    it 'updates all the attributes' do
      LinkCheckRule.stub(:find) { link_check_rule }
      link_check_rule.should_receive(:update_attributes).with('collection_title' => 'collection_title', 'status_codes' => '203,205')
      put :update, params: { id: link_check_rule.id, link_check_rule: { collection_title: 'collection_title', status_codes: '203,205' } }
    end
  end

  describe 'DELETE destroy' do
    it 'finds the collection rule and destroys it' do
      LinkCheckRule.should_receive(:find) { link_check_rule }
      delete :destroy, params: { id: link_check_rule.id }
    end
  end
end
