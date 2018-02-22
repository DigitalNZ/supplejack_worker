# frozen_string_literal: true
require 'rails_helper'

describe LinkCheckRule do
  let(:rule) { build(:link_check_rule) }

  describe 'validations' do
    it 'should not be valid without a source' do
      rule.source_id = nil
      rule.should_not be_valid
    end

    it 'should not be valid without a unique source' do
      rule.save!
      same_rule = build(:link_check_rule, source_id: rule.source_id)
      same_rule.should_not be_valid
    end
  end
end
