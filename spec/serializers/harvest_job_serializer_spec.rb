require 'rails_helper'

describe HarvestJobSerializer do
  let!(:harvest_job) { FactoryBot.create(:harvest_job) }
  let(:serialized) { described_class.new(harvest_job) }

  it 'renders _type attribute with proper value' do
    expect(serialized.serializable_hash[:_type]).to eq harvest_job._type
  end
end
