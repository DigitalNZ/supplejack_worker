# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe LinkCheckRule do
  let(:rule) { FactoryBot.build(:link_check_rule) }

  describe "validations" do
    it "should not be valid without a source" do
      rule.source_id = nil
      rule.should_not be_valid
    end

    it "should not be valid without a unique source" do
      rule.save!
      same_rule = FactoryBot.build(:link_check_rule, source_id: rule.source_id)
      same_rule.should_not be_valid
    end
  end
end
