# frozen_string_literal: true

require 'rails_helper'

describe Matcher::ConceptMatcher do
  class TestWorker
    include Matcher::ConceptMatcher
  end

  let(:worker) { TestWorker.new }

  let(:attributes) do
    { priority: 0, source_id: 'mccahon_co_nz', match_concepts: :create_or_match,
      internal_identifier: 'http://www.mccahon.co.nz/',
      givenName: 'Colin', familyName: 'McCahon',
      dateOfBirth: DateTime.parse('1919-01-01'), dateOfDeath: DateTime.parse('1987-01-01'),
      sameAs: ['http://www.en.wikipedia.com/mccahon'] }
  end

  let(:fragment) { SupplejackApi::ApiConcept::ConceptFragment.new(attributes) }
  let(:concept) { SupplejackApi::Concept.create(landing_url: 'http://www.mccahon.co.nz/', internal_identifier: 'http://www.mccahon.co.nz/', status: 'active') }

  before(:each) do
    concept.fragments = [fragment]
    concept.save!
    fragment.update_attribute(:source_id, 'te-papa')
  end

  describe '#create_concept?' do
    context 'create_or_match' do
      it 'returns false as matches existing concept' do
        expect(worker.create_concept?(attributes)).to be_falsey
      end

      it 'returns true as doesn\'t match existing concept' do
        expect(worker.create_concept?(attributes.merge(givenName: 'Noname'))).to be_truthy
      end
    end

    context 'create' do
      it 'returns true as doesn\'t matter if it matches' do
        expect(worker.create_concept?(attributes.merge(match_concepts: :create))).to be_truthy
      end
    end

    context 'match' do
      it 'returns false as matches existing concept' do
        expect(worker.create_concept?(attributes.merge(match_concepts: :match))).to be_falsey
      end
    end

    it 'converts arrays into single fields' do
      attributes[:givenName] = ['John']
      expect(worker).to receive(:lookup).with(hash_including(givenName: 'John'))
      worker.create_concept?(attributes)
    end

    it 'does not perform a lookup if no job is given' do
      attributes.delete(:dateOfBirth)
      expect(worker).to_not receive(:lookup)
      expect(worker.create_concept?(attributes)).to be_falsey
    end
  end

  describe 'lookup' do
    it 'looks up the concept on name and date of birth/death' do
      expect(worker.send(:lookup, attributes)).to be_truthy
    end

    context 'match found' do
      before(:each) do
        query = double(:query, first: concept).as_null_object
        allow(SupplejackApi::Concept).to receive(:where).and_return(query)
      end

      it 'does not post an update if the source is reharvested' do
        fragment.update_attribute(:source_id, 'mccahon_co_nz')
        worker.send(:lookup, attributes)
        expect(ApiUpdateWorker).not_to have_enqueued_sidekiq_job('/harvester/concepts.json', { 'concept' => { 'internal_identifier' => 'http://www.mccahon.co.nz/', 'source_id' => 'mccahon_co_nz', 'sameAs' => 'http://www.mccahon.co.nz/', 'match_status' => 'strong' } }, nil)
      end

      it 'posts an update to the API with the sameAs and match_status fields' do
        worker.send(:lookup, attributes)
        expect(ApiUpdateWorker).to have_enqueued_sidekiq_job('/harvester/concepts.json', { 'concept' => { 'internal_identifier' => 'http://www.mccahon.co.nz/', 'source_id' => 'mccahon_co_nz', 'sameAs' => ['http://www.en.wikipedia.com/mccahon'], 'match_status' => 'strong' } }, nil)
      end
    end
  end
end
