require "spec_helper"

describe Snippet do
  
  let(:snippet) { Snippet.new(name: "Copyright") }

  describe ".find_by_name" do
    it "finds the snippet" do
      Snippet.should_receive(:find).with(:one, from: :search, params: {name: "Copyright"}) { snippet }
      Snippet.find_by_name("Copyright").should eq snippet
    end
  end
end