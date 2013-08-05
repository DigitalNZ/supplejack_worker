require "spec_helper"

describe EnqueueCollectionChecksWorker do

  let(:worker) { EnqueueCollectionChecksWorker.new }
  
  let(:collection_rules) { [double(:collection_rule, collection_title: "TAPUHI", active: true),
                            double(:collection_rule, collection_title: "NLNZCat", active: true),
                            double(:collection_rule, collection_title: "NZ On Screen", active: false)] }

  before { CollectionRules.stub(:all) { collection_rules } }

  describe "#perform" do
    it "should enqueue a collection check worker for each collection to check" do
      worker.perform
      ["TAPUHI", "NLNZCat"].each do |collection|
        expect(CollectionCheckWorker).to have_enqueued_job(collection)
      end
    end
  end

  describe ".collections_to_check" do

    it "should get all the collections to check" do
      EnqueueCollectionChecksWorker.collections_to_check.should include("TAPUHI", "NLNZCat")
    end

    it "should not include inactive collections" do
      EnqueueCollectionChecksWorker.collections_to_check.should_not include("NZ On Screen")
    end
  end
end