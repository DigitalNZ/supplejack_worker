require 'spec_helper'

describe CollectionRulesController do

  let(:collection_rule) { mock_model(CollectionRules, collection_title: "TAPUHI").as_null_object }
  let(:user) { mock_model(User).as_null_object }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
    controller.stub(:current_user) { user }
  end

  describe "GET 'index'" do
    it "should get all of the collection rules" do
      CollectionRules.should_receive(:all) { [collection_rule] }
      get :index
      assigns(:collection_rules).should eq [collection_rule]
    end

    it "should do a where if collection_rules is defined" do
      params = {collection_rules: {collection_title: "TAPUHI"}}
      CollectionRules.should_receive(:where).with(params[:collection_rules].stringify_keys)
      get :index, params
    end
  end

  describe "GET 'show'" do
    it "should get the collection rule" do
      CollectionRules.should_receive(:find) { collection_rule }
      get :show, id: collection_rule.id
      assigns(:collection_rule).should eq collection_rule
    end
  end

  describe "POST 'create'" do
    it "should make a new collection rule and assign it" do
      CollectionRules.should_receive(:create).with({ "collection_title" => "TAPUHI", "status_codes" => "203,205" }) { collection_rule }
      post :create, collection_rules: { collection_title: "TAPUHI", status_codes: "203,205" }
      assigns(:collection_rule) { collection_rule }
    end
  end

  describe "PUT 'update'" do
    it "should find the collection_rule" do
      CollectionRules.should_receive(:find) { collection_rule }
      put :update, id: collection_rule.id, collection_rule: { collection_title: "TAPUHI", status_codes: "203,205" }
      assigns(:collection_rule) { collection_rule }
    end

    it "updates all the attributes" do
      CollectionRules.stub(:find) { collection_rule }
      collection_rule.should_receive(:update_attributes).with({"collection_title" => "TAPUHI", "status_codes" => "203,205" })
      put :update, id: collection_rule.id, collection_rules: { collection_title: "TAPUHI", status_codes: "203,205" }
    end
  end

  describe "DELETE 'destroy'" do
    it "finds the collection rule and destroys it" do
      CollectionRules.should_receive(:find) { collection_rule }
      delete :destroy, id: collection_rule.id
    end
  end

end

