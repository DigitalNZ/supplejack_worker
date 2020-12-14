# frozen_string_literal: true

require 'rails_helper'

describe LinkCheckRule do
  let(:rule) { build(:link_check_rule) }

  describe 'validations' do
    it 'is not valid without a source' do
      rule.source_id = nil
      expect(rule).to_not be_valid
    end

    it 'is not valid without a unique source' do
      rule.save!
      same_rule = build(:link_check_rule, source_id: rule.source_id)
      expect(same_rule).to_not be_valid
    end
  end
end
