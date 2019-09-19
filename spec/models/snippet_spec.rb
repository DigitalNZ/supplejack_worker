require "spec_helper"

describe Snippet do

  let(:snippet) { Snippet.new(name: "Copyright") }

  describe ".find_by_name" do
    it "finds the snippet" do
      Snippet.should_receive(:find).with(:one, from: :current_version, params: {name: "Copyright", environment: :staging}) { snippet }
      Snippet.find_by_name("Copyright", :staging).should eq snippet
    end

    it "returns nil when a error is raised" do
      Snippet.stub(:find).and_raise(ArgumentError)
      Snippet.find_by_name("dsfsd", :staging).should be_nil
    end
  end
end
