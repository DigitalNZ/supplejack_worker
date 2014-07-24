require 'spec_helper'

describe Matcher::ConceptMatcher do
  class TestWorker
    include Matcher::ConceptMatcher
  end
  let(:worker) { TestWorker.new }

  let(:attributes) { {priority: 0, source_id: 'mccahon_co_nz', match_concepts: :create_or_match, 
                      internal_identifier: 'http://www.mccahon.co.nz/',
                      givenName: 'Colin', familyName: 'McCahon',
                      dateOfBirth: DateTime.parse('1919-01-01'), dateOfDeath: DateTime.parse('1987-01-01'),
                      sameAs: ['http://www.en.wikipedia.com/mccahon']} }
  
  let(:fragment) { SupplejackApi::ApiConcept::ConceptFragment.new(attributes) }
  let(:concept) { SupplejackApi::Concept.create(landing_url: 'http://www.mccahon.co.nz/', internal_identifier: 'http://www.mccahon.co.nz/', status: 'active') }

  before(:each) do
    concept.fragments = [fragment]
    concept.save!
    fragment.update_attribute(:source_id, 'te-papa')
  end

  describe "#create_concept?" do
    context "create_or_match" do
      it "should return false as matches existing concept" do
        worker.create_concept?(attributes).should be_false
      end

      it "should return true as doesn't match existing concept" do
        worker.create_concept?(attributes.merge(givenName: 'Noname')).should be_true
      end
    end

    context "create" do
      it "should return true as doesn't matter if it matches" do
        worker.create_concept?(attributes.merge(match_concepts: :create)).should be_true
      end
    end

    context "match" do
      it "should return false as matches existing concept" do
        worker.create_concept?(attributes.merge(match_concepts: :match)).should be_false
      end
    end

    it "should convert arrays into single fields" do
      attributes[:givenName] = ['John']
      worker.should_receive(:lookup).with(hash_including(givenName: 'John'))
      worker.create_concept?(attributes)
    end

    it "should not perform a lookup if no dob is given" do
      attributes.delete(:dateOfBirth)
      worker.should_not_receive(:lookup)
      worker.create_concept?(attributes).should be_false
    end
  end

  describe "lookup" do
    it "should lookup the concept on name and date of birth/death" do
      worker.send(:lookup, attributes).should be_true
    end

    context "match found" do
      before(:each) do
        query = double(:query, first: concept).as_null_object
        SupplejackApi::Concept.stub(:where) { query }
      end

      it "should not post an update if the source is reharvested" do
        fragment.update_attribute(:source_id, 'mccahon_co_nz')
        worker.send(:lookup, attributes)
        expect(ApiUpdateWorker).not_to have_enqueued_job("/harvester/concepts.json", {"concept"=>{"internal_identifier"=>"http://www.mccahon.co.nz/", "source_id" => "mccahon_co_nz", "sameAs"=>"http://www.mccahon.co.nz/", "match_status"=>"strong"}}, nil)
      end

      it "should post an update to the API with the sameAs and match_status fields" do
        worker.send(:lookup, attributes)
        expect(ApiUpdateWorker).to have_enqueued_job("/harvester/concepts.json", {"concept"=>{"internal_identifier"=>"http://www.mccahon.co.nz/", "source_id" => "mccahon_co_nz", "sameAs"=>["http://www.en.wikipedia.com/mccahon"], "match_status"=>"strong"}}, nil)
      end
    end
  end
end
