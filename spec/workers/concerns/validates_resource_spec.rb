require "spec_helper"

describe ValidatesResource do

  class TestWorker
    include ValidatesResource
  end

  let(:worker) { TestWorker.new }
  let(:collection_rule) { double(:collection_rule, status_codes: "200, 3..", xpath: '//p', throttle: 3, active: true) }

  describe "#validate_collection_rules" do
    let(:response) { double(:response, code: 200, body: "<p></p>") }

    before do
      CollectionRules.stub(:find) { [collection_rule] }
      worker.stub(:link_check_job) { link_check_job }
    end

    it "should validate the response codes" do
      worker.should_receive(:validate_response_codes).with(305, "200, 3..")
      worker.send(:validate_collection_rules, double(:response, code: 305, body: "<p></p>"), 'TAPUHI')
    end

    it "should validate the response body via xpath" do
      worker.should_receive(:validate_xpath).with("//p", "<p></p>")
      worker.send(:validate_collection_rules, response, 'TAPUHI')
    end

    context "response code and xpath is valid" do
      it "should return true" do
        worker.stub(:validate_response_codes) { true }
        worker.stub(:validate_xpath) { true }
        worker.send(:validate_collection_rules, response, 'TAPUHI').should be_true
      end
    end

    context "only response code is invalid" do
      it "should return false" do
        worker.stub(:validate_response_codes) { false }
        worker.stub(:validate_xpath) { true }
        worker.send(:validate_collection_rules, response, 'TAPUHI').should be_false
      end
    end

    context "only validate xpath is invalid" do
      it "should return false" do
        worker.stub(:validate_response_codes) { true }
        worker.stub(:validate_xpath) { false }
        worker.send(:validate_collection_rules, response, 'TAPUHI').should be_false
      end
    end

    context "response code and xpath are invalid" do
      it "should return true" do
        worker.stub(:validate_response_codes) { false }
        worker.stub(:validate_xpath) { false }
        worker.send(:validate_collection_rules, response, 'TAPUHI').should be_false
      end
    end
  end

  describe "validate_response_codes" do
    it "should return false when the response code matches the string" do
      worker.send(:validate_response_codes, 300, '300').should be_false
    end

    it "should return false when the response code matches the regex" do
      worker.send(:validate_response_codes, 201, '300, 2..').should be_false
      worker.send(:validate_response_codes, 300, '300, 2..').should be_false
    end

    it "should return true if response code blacklist is nil" do
      worker.send(:validate_response_codes, 201, nil).should be_true
    end
  end

  describe "#validate_xpath" do
    it "should return false when the xpath expression matches" do
      worker.send(:validate_xpath, '//p[@class="error"]', '<p class="error">Page Not Found</p>').should be_false
    end

    it "should return true when the xpath expression doesn't match" do
      worker.send(:validate_xpath, '//p[@class="error"]', '<a class="large">Title</a>').should be_true
    end

    it "should return true when there is no xpath" do
      worker.send(:validate_xpath, nil, '<a class="large">Title</a>').should be_true
    end

    it "should return true when there is no xpath" do
      worker.send(:validate_xpath, "", '<a class="large">Title</a>').should be_true
    end
  end

  describe "#collection_rule" do

    it "should should find the collection rule" do
      CollectionRules.should_receive(:find).with(:all, params: { collection_rules: { collection_title: 'TAPUHI'}}) { [] }
      worker.send(:collection_rule, 'TAPUHI')
    end

    it "should memozie the collection rule" do
      CollectionRules.should_receive(:find).once { [double(:collection_rule)] }
      worker.send(:collection_rule, 'TAPUHI')
      worker.send(:collection_rule, 'TAPUHI')
    end
  end
end