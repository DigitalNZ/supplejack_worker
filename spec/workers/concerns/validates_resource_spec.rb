# frozen_string_literal: true
require 'rails_helper'

describe ValidatesResource do
  class TestWorker
    include ValidatesResource
  end

  let(:worker) { TestWorker.new }
  let(:link_check_rule) { double(:link_check_rule, status_codes: '200, 3..', xpath: '//p', throttle: 3, active: true) }

  describe '#validate_link_check_rule' do
    let(:response) { double(:response, code: 200, body: '<p></p>') }

    before do
      allow(LinkCheckRule).to receive(:find_by) { link_check_rule }
    end

    it 'should validate the response codes' do
      expect(worker).to receive(:validate_response_codes).with(305, '200, 3..')
      worker.send(:validate_link_check_rule, double(:response, code: 305, body: '<p></p>'), 'RULE_NAME')
    end

    it 'should validate the response body via xpath' do
      expect(worker).to receive(:validate_xpath).with('//p', '<p></p>')
      worker.send(:validate_link_check_rule, response, 'RULE_NAME')
    end

    context 'response code and xpath is valid' do
      it 'should return true' do
        allow(worker).to receive(:validate_response_codes) { true }
        allow(worker).to receive(:validate_xpath) { true }
        expect(worker.send(:validate_link_check_rule, response, 'RULE_NAME')).to be_truthy
      end
    end

    context 'only response code is invalid' do
      it 'should return false' do
        allow(worker).to receive(:validate_response_codes) { false }
        allow(worker).to receive(:validate_xpath) { true }
        expect(worker.send(:validate_link_check_rule, response, 'RULE_NAME')).to be_falsey
      end
    end

    context 'only validate xpath is invalid' do
      it 'should return false' do
        allow(worker).to receive(:validate_response_codes) { true }
        allow(worker).to receive(:validate_xpath) { false }
        expect(worker.send(:validate_link_check_rule, response, 'RULE_NAME')).to be_falsey
      end
    end

    context 'response code and xpath are invalid' do
      it 'should return true' do
        allow(worker).to receive(:validate_response_codes) { false }
        allow(worker).to receive(:validate_xpath) { false }
        expect(worker.send(:validate_link_check_rule, response, 'RULE_NAME')).to be_falsey
      end
    end
  end

  describe 'validate_response_codes' do
    it 'should return false when the response code matches the string' do
      expect(worker.send(:validate_response_codes, 300, '300')).to be_falsey
    end

    it 'should return false when the response code matches the regex' do
      expect(worker.send(:validate_response_codes, 201, '300, 2..')).to be_falsey
      expect(worker.send(:validate_response_codes, 300, '300, 2..')).to be_falsey
    end

    it 'should return true if response code blacklist is nil' do
      expect(worker.send(:validate_response_codes, 201, nil)).to be_truthy
    end
  end

  describe '#validate_xpath' do
    it 'should return false when the xpath expression matches' do
      expect(worker.send(:validate_xpath, '//p[@class="error"]', '<p class="error">Page Not Found</p>')).to be_falsey
    end

    it "should return true when the xpath expression doesn't match" do
      expect(worker.send(:validate_xpath, '//p[@class="error"]', '<a class="large">Title</a>')).to be_truthy
    end

    it 'should return true when there is no xpath' do
      expect(worker.send(:validate_xpath, nil, '<a class="large">Title</a>')).to be_truthy
    end

    it 'should return true when there is no xpath' do
      expect(worker.send(:validate_xpath, '', '<a class="large">Title</a>')).to be_truthy
    end
  end

  describe '#link_check_rule' do
    it 'should should find the collection rule' do
      expect(LinkCheckRule).to receive(:find_by).with(source_id: 'source_id') {}
      worker.send(:link_check_rule, 'source_id')
    end

    it 'should memozie the collection rule' do
      expect(LinkCheckRule).to receive(:find_by).once { [double(:link_check_rule)] }
      worker.send(:link_check_rule, 'RULE_NAME')
      worker.send(:link_check_rule, 'RULE_NAME')
    end
  end
end
