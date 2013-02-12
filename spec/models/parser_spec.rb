require 'spec_helper'

describe Parser do

  let(:parser) { Parser.new(name: "Europeana") }

  describe "#loader" do
    it "should initialize a loader object" do
      ParserLoader.should_receive(:new).with(parser)
      parser.loader
    end
  end

  describe "#load" do
    let!(:loader) { mock(:loader).as_null_object }

    before(:each) do
      parser.stub(:loader) { loader }
    end

    it "should load the parser file" do
      loader.should_receive(:load_parser)
      parser.load_file
    end
  end
end
