# frozen_string_literal: true

require 'rails_helper'

describe NetworkChecker do
  describe '#check' do
    it 'requests the Google homepage' do
      expect(RestClient).to receive(:get).with('http://google.com').and_return double(:response, code: 200)
      NetworkChecker.check
    end

    it 'enables link checking if HTTP 200 response' do
      ENV['LINK_CHECKING_ENABLED'] = nil
      allow(RestClient).to receive(:get).and_return double(:response, code: 200)
      NetworkChecker.check
      expect(ENV['LINK_CHECKING_ENABLED']).to eq 'true'
    end

    it 'disables link checking on RestClient errors' do
      ENV['LINK_CHECKING_ENABLED'] = 'true'
      allow(RestClient).to receive(:get).and_raise(RestClient::ResourceNotFound)
      NetworkChecker.check
      expect(ENV['LINK_CHECKING_ENABLED']).to be_nil
    end
  end
end
