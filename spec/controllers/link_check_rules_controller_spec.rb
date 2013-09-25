require 'spec_helper'

describe LinkCheckRulesController do

  let(:link_check_rule) { mock_model(LinkCheckRule, collection_title: "TAPUHI").as_null_object }
  let(:user) { mock_model(User).as_null_object }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
    controller.stub(:current_user) { user }
  end

  describe "GET 'index'" do
    it "should get all of the collection rules" do
      LinkCheckRule.should_receive(:all) { [link_check_rule] }
      get :index
      assigns(:link_check_rules).should eq [link_check_rule]
    end

    it "should do a where if link_check_rule is defined" do
      params = {link_check_rule: {collection_title: "TAPUHI"}}
      LinkCheckRule.should_receive(:where).with(params[:link_check_rule].stringify_keys)
      get :index, params
    end
  end

  describe "GET 'show'" do
    it "should get the collection rule" do
      LinkCheckRule.should_receive(:find) { link_check_rule }
      get :show, id: link_check_rule.id
      assigns(:link_check_rule).should eq link_check_rule
    end
  end

  describe "POST 'create'" do
    it "should make a new collection rule and assign it" do
      LinkCheckRule.should_receive(:create).with({ "collection_title" => "TAPUHI", "status_codes" => "203,205" }) { link_check_rule }
      post :create, link_check_rule: { collection_title: "TAPUHI", status_codes: "203,205" }
      assigns(:link_check_rule) { link_check_rule }
    end
  end

  describe "PUT 'update'" do
    it "should find the link_check_rule" do
      LinkCheckRule.should_receive(:find) { link_check_rule }
      put :update, id: link_check_rule.id, link_check_rule: { collection_title: "TAPUHI", status_codes: "203,205" }
      assigns(:link_check_rule) { link_check_rule }
    end

    it "updates all the attributes" do
      LinkCheckRule.stub(:find) { link_check_rule }
      link_check_rule.should_receive(:update_attributes).with({"collection_title" => "TAPUHI", "status_codes" => "203,205" })
      put :update, id: link_check_rule.id, link_check_rule: { collection_title: "TAPUHI", status_codes: "203,205" }
    end
  end

  describe "DELETE 'destroy'" do
    it "finds the collection rule and destroys it" do
      LinkCheckRule.should_receive(:find) { link_check_rule }
      delete :destroy, id: link_check_rule.id
    end
  end

end

