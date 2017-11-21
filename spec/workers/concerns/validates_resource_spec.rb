# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe ValidatesResource do

  class TestWorker
    include ValidatesResource
  end

  let(:worker) { TestWorker.new }
  let(:link_check_rule) { double(:link_check_rule, status_codes: "200, 3..", xpath: '//p', throttle: 3, active: true) }

  describe "#validate_link_check_rule" do
    let(:response) { double(:response, code: 200, body: "<p></p>") }

    before do
      LinkCheckRule.stub(:find_by) { link_check_rule }
    end

    it "should validate the response codes" do
      worker.should_receive(:validate_response_codes).with(305, "200, 3..")
      worker.send(:validate_link_check_rule, double(:response, code: 305, body: "<p></p>"), 'RULE_NAME')
    end

    it "should validate the response body via xpath" do
      worker.should_receive(:validate_xpath).with("//p", "<p></p>")
      worker.send(:validate_link_check_rule, response, 'RULE_NAME')
    end

    context "response code and xpath is valid" do
      it "should return true" do
        worker.stub(:validate_response_codes) { true }
        worker.stub(:validate_xpath) { true }
        worker.send(:validate_link_check_rule, response, 'RULE_NAME').should be_truthy
      end
    end

    context "only response code is invalid" do
      it "should return false" do
        worker.stub(:validate_response_codes) { false }
        worker.stub(:validate_xpath) { true }
        worker.send(:validate_link_check_rule, response, 'RULE_NAME').should be_falsey
      end
    end

    context "only validate xpath is invalid" do
      it "should return false" do
        worker.stub(:validate_response_codes) { true }
        worker.stub(:validate_xpath) { false }
        worker.send(:validate_link_check_rule, response, 'RULE_NAME').should be_falsey
      end
    end

    context "response code and xpath are invalid" do
      it "should return true" do
        worker.stub(:validate_response_codes) { false }
        worker.stub(:validate_xpath) { false }
        worker.send(:validate_link_check_rule, response, 'RULE_NAME').should be_falsey
      end
    end
  end

  describe "validate_response_codes" do
    it "should return false when the response code matches the string" do
      worker.send(:validate_response_codes, 300, '300').should be_falsey
    end

    it "should return false when the response code matches the regex" do
      worker.send(:validate_response_codes, 201, '300, 2..').should be_falsey
      worker.send(:validate_response_codes, 300, '300, 2..').should be_falsey
    end

    it "should return true if response code blacklist is nil" do
      worker.send(:validate_response_codes, 201, nil).should be_truthy
    end
  end

  describe "#validate_xpath" do
    it "should return false when the xpath expression matches" do
      worker.send(:validate_xpath, '//p[@class="error"]', '<p class="error">Page Not Found</p>').should be_falsey
    end

    it "should return true when the xpath expression doesn't match" do
      worker.send(:validate_xpath, '//p[@class="error"]', '<a class="large">Title</a>').should be_truthy
    end

    it "should return true when there is no xpath" do
      worker.send(:validate_xpath, nil, '<a class="large">Title</a>').should be_truthy
    end

    it "should return true when there is no xpath" do
      worker.send(:validate_xpath, "", '<a class="large">Title</a>').should be_truthy
    end
  end

  describe "#link_check_rule" do

    it "should should find the collection rule" do
      LinkCheckRule.should_receive(:find_by).with(source_id: 'source_id') { }
      worker.send(:link_check_rule, 'source_id')
    end

    it "should memozie the collection rule" do
      LinkCheckRule.should_receive(:find_by).once { [double(:link_check_rule)] }
      worker.send(:link_check_rule, 'RULE_NAME')
      worker.send(:link_check_rule, 'RULE_NAME')
    end
  end
end
