# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Request do
  describe '#initialize' do
    it 'sets the url' do
      request = described_class.new('/test')
      expect(request.url).to include(ENV['API_HOST'])
    end

    it 'appends .json to the path' do
      request = described_class.new('/test')
      expect(request.url).to end_with('/test.json')
    end

    it 'stores the token' do
      request = described_class.new('/test')
      expect(request.token).to include(ENV['HARVESTER_API_KEY'])
    end

    it 'stores the params ready to be used by RestClient if present' do
      request = described_class.new('/test', { param: :value })
      expect(request.params).to eq(param: :value)
    end

    it 'stores the params as empty hash if not present' do
      request = described_class.new('/test')
      expect(request.params).to eq({})
    end
  end

  %i[get post put patch delete].each do |method|
    describe "##{method}" do
      it "only calls execute with the #{method} method" do
        request = described_class.new('/test')
        expect(request).to receive(:execute).with(method)
        request.send(method)
      end
    end
  end

  describe '#execute' do
    it 'sends the right method' do
      request = described_class.new('/test')
      expect(RestClient::Request).to receive(:execute).with(hash_including(method: :get))
      request.get

      request = described_class.new('/test')
      expect(RestClient::Request).to receive(:execute).with(hash_including(method: :put))
      request.put
    end

    it 'sends to the set url' do
      request = described_class.new('/test')
      expect(RestClient::Request).to receive(:execute).with(hash_including(url: request.url))
      request.get
    end

    it 'sends the Authentication-Token header' do
      request = described_class.new('/test')
      expect(RestClient::Request).to receive(:execute).with(hash_including(
        headers: { 'Authentication-Token': request.token }
      ))
      request.get
    end

    it 'sends params in the URL if GET or DELETE' do
      expected_hash = {
        payload: nil,
        headers: {
          'Authentication-Token': ENV['HARVESTER_API_KEY'],
          params: { param: :value }
        }
      }
      expect(RestClient::Request).to receive(:execute).with(hash_including(expected_hash))
      described_class.new('/test', { param: :value }).get

      expect(RestClient::Request).to receive(:execute).with(hash_including(expected_hash))
      described_class.new('/test', { param: :value }).delete
    end

    it 'sends params in the payload if PUT or PATCH or POST' do
      expected_hash = {
        payload: { param: :value },
        headers: {
          'Authentication-Token': ENV['HARVESTER_API_KEY'],
        }
      }
      expect(RestClient::Request).to receive(:execute).with(hash_including(expected_hash))
      described_class.new('/test', { param: :value }).put

      expect(RestClient::Request).to receive(:execute).with(hash_including(expected_hash))
      described_class.new('/test', { param: :value }).patch

      expect(RestClient::Request).to receive(:execute).with(hash_including(expected_hash))
      described_class.new('/test', { param: :value }).post
    end
  end
end
