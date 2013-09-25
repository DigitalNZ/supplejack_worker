require "spec_helper"

describe EnqueueSourceChecksWorker do

  let(:worker) { EnqueueSourceChecksWorker.new }
  
  let(:link_check_rules) { [double(:link_check_rule, source_id: "1", active: true),
                            double(:link_check_rule, source_id: "2", active: true),
                            double(:link_check_rule, source_id: "3", active: false)] }

  before { LinkCheckRule.stub(:all) { link_check_rules } }

  describe "#perform" do
    it "should enqueue a source check worker for each source to check" do
      worker.perform
      ["1", "2"].each do |source|
        expect(SourceCheckWorker).to have_enqueued_job(source)
      end
    end
  end

  describe ".sources_to_check" do

    it "should get all the sources to check" do
      EnqueueSourceChecksWorker.sources_to_check.should include("1", "2")
    end

    it "should not include inactive sources" do
      EnqueueSourceChecksWorker.sources_to_check.should_not include("3")
    end
  end
end