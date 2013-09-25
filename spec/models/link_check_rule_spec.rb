require 'spec_helper'

describe CollectionRules do
  let(:rule) { FactoryGirl.build(:collection_rule) }

  describe "validations" do
    it "should not be valid without a source_id" do
      rule.source_id = nil
      rule.should_not be_valid
    end

    it "should not be valid without a unique collection title" do
      rule.save!
      same_rule = FactoryGirl.build(:collection_rule)
      same_rule.should_not be_valid
    end
  end
end
