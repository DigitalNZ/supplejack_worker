require "spec_helper"

describe SharedModule do
  
  let(:shared_module) { SharedModule.new(name: "Copyright") }

  describe ".find_by_name" do
    it "finds the shared module" do
      SharedModule.should_receive(:find).with(:one, from: :search, params: {name: "Copyright"}) { shared_module }
      SharedModule.find_by_name("Copyright").should eq shared_module
    end
  end
end