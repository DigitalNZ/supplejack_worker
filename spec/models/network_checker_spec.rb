# frozen_string_literal: true
require 'rails_helper'

describe NetworkChecker do
  describe '#check' do
    it 'should request the Google homepage' do
      RestClient.should_receive(:get).with('http://google.com') { double(:response, code: 200) }
      NetworkChecker.check
    end

    it 'should enable link checking if 200 response' do
      ENV['LINK_CHECKING_ENABLED'] = nil
      RestClient.stub(:get) { double(:response, code: 200) }
      NetworkChecker.check
      ENV['LINK_CHECKING_ENABLED'].should eq 'true'
    end

    it 'should disable link checking on RestClient errors' do
      ENV['LINK_CHECKING_ENABLED'] = 'true'
      RestClient.stub(:get).and_raise(RestClient::ResourceNotFound)
      NetworkChecker.check
      ENV['LINK_CHECKING_ENABLED'].should be_nil
    end
  end
end
