# frozen_string_literal: true
require 'rails_helper'

describe LinkCheckRulesController do
  let(:link_check_rule) { create(:link_check_rule) }

  describe 'authorized requests' do
    before(:each) do
      request.headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
    end

    describe 'GET index' do
      it 'returns all of the collection rules' do
        allow(LinkCheckRule).to receive(:all).and_return([link_check_rule])
        get :index, params: {}, format: 'json'
        expect(assigns(:link_check_rules)).to eq [link_check_rule]
      end

      it 'performs a where if link_check_rule is defined' do
        params = { link_check_rule: { collection_title: 'link_check_rule' } }
        expect(LinkCheckRule).to receive(:where).with(params[:link_check_rule].stringify_keys)
        get :index, params: params, format: 'json'
      end
    end

    describe 'GET show' do
      it 'finds the collection rule' do
        allow(LinkCheckRule).to receive(:find).and_return(link_check_rule)
        get :show, params: { id: link_check_rule.id }
        expect(assigns(:link_check_rule)).to eq link_check_rule
      end
    end

    describe 'POST create' do
      it 'creates a new collection rule and assign it' do
        params = ActionController::Parameters.new('collection_title' => 'collection_title', 'status_codes' => '203,205', source_id: 'source_id').permit!
        allow(LinkCheckRule).to receive(:create!).with(params).and_return(link_check_rule)
        post :create, params: { link_check_rule: { collection_title: 'collection_title', status_codes: '203,205', source_id: 'source_id' } }
        expect(assigns(:link_check_rule)).to eq link_check_rule
      end
    end

    describe 'PUT update' do
      it 'finds the link_check_rule' do
        allow(LinkCheckRule).to receive(:find).and_return(link_check_rule)
        put :update, params: { id: link_check_rule.id, link_check_rule: { collection_title: 'collection_title', status_codes: '203,205' } }
        expect(assigns(:link_check_rule)).to eq link_check_rule
      end

      it 'updates all the attributes' do
        allow(LinkCheckRule).to receive(:find).and_return(link_check_rule)
        expect(link_check_rule).to receive(:update).with('collection_title' => 'collection_title', 'status_codes' => '203,205')
        put :update, params: { id: link_check_rule.id, link_check_rule: { collection_title: 'collection_title', status_codes: '203,205' } }
      end
    end

    describe 'DELETE destroy' do
      it 'finds the collection rule and destroys it' do
        expect(LinkCheckRule).to receive(:find).and_return(link_check_rule)
        delete :destroy, params: { id: link_check_rule.id }
      end
    end
  end

  it 'prevent access if worker_key is not provided' do
    get :index, params: { status: 'active' }
    expect(response.status).to eq(401)
  end
end
