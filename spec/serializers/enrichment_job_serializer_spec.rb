require 'rails_helper'

describe EnrichmentJobSerializer do
  let!(:enrichment_job) { create(:enrichment_job) }
  let(:serialized) { described_class.new(enrichment_job) }

  it 'renders _type attribute with proper value' do
    expect(serialized.serializable_hash[:_type]).to eq enrichment_job._type
  end
end
