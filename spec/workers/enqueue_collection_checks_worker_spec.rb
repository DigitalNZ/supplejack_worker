require "spec_helper"

describe EnqueueCollectionChecksWorker do

  let(:worker) { EnqueueCollectionChecksWorker.new }
  
  let(:collection_rules) { [double(:collection_rule, source_id: "tapuhi", active: true),
                            double(:collection_rule, source_id: "nlnzcat", active: true),
                            double(:collection_rule, source_id: "nz-on-screen", active: false)] }

  before { CollectionRules.stub(:all) { collection_rules } }

  describe "#perform" do
    it "should enqueue a collection check worker for each collection to check" do
      worker.perform
      ["tapuhi", "nlnzcat"].each do |collection|
        expect(CollectionCheckWorker).to have_enqueued_job(collection)
      end
    end
  end

  describe ".collections_to_check" do

    it "should get all the collections to check" do
      EnqueueCollectionChecksWorker.collections_to_check.should include("tapuhi", "nlnzcat")
    end

    it "should not include inactive collections" do
      EnqueueCollectionChecksWorker.collections_to_check.should_not include("nz-on-screen")
    end
  end
end