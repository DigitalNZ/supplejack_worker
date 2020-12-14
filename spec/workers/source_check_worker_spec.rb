# frozen_string_literal: true

require 'rails_helper'

describe SourceCheckWorker do
  let(:worker) { SourceCheckWorker.new }
  let(:source) { double(:source, source_id: 'source_id', id: 'abc123') }

  before(:each) do
    worker.instance_variable_set(:@primary_collection, 'NAME')
    worker.instance_variable_set(:@source, source)
  end

  describe '#perform' do
    let(:records) { ['http://google.com/1', 'http://google.com/2'] }

    before(:each) do
      allow(Source).to receive(:find).and_return(source)
      allow(worker).to receive(:source_active?).and_return true
      allow(worker).to receive(:suppress_collection)
    end

    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'retrieves landing urls from the API to check' do
      allow(worker).to receive(:up?).and_return true

      expect(worker).to receive(:source_records).and_return records

      worker.perform('NAME')
    end

    it 'checks that the records are up' do
      allow(worker).to receive(:source_records).and_return records

      expect(worker).to receive(:up?).with('http://google.com/1')
      expect(worker).to receive(:up?).with('http://google.com/2')

      worker.perform('NAME')
    end

    context 'the collection is active and all links are down' do
      before do
        allow(worker).to receive(:source_active?).and_return true
        allow(worker).to receive(:source_records).and_return records
        allow(worker).to receive(:up?).with('http://google.com/1').and_return false
        allow(worker).to receive(:up?).with('http://google.com/2').and_return false
      end

      it 'adds the collection to the blacklist' do
        expect(worker).to receive(:suppress_collection)
        worker.perform('NAME')
      end
    end

    context 'the collection is not active and any of the links are up' do
      before do
        allow(worker).to receive(:source_active?).and_return false
        allow(worker).to receive(:source_records).and_return records
        allow(worker).to receive(:up?).with('http://google.com/1').and_return true
        allow(worker).to receive(:up?).with('http://google.com/2').and_return false
      end

      it 'removes the collection from the blacklist' do
        expect(worker).to receive(:activate_collection)
        worker.perform('NAME')
      end
    end
  end

  describe 'source_records' do
    let(:response) { double(:response) }

    before do
      allow(JSON).to receive(:parse).and_return []
      allow(RestClient).to receive(:get).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}/link_check_records").and_return response
    end

    it 'retrieves landing urls from the API to check' do
      expect(RestClient).to receive(:get).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}/link_check_records",
params: { api_key: ENV['HARVESTER_API_KEY'] }).and_return response
      worker.send(:source_records)
    end
  end

  describe 'source_active?' do
    before(:each) do
      allow(RestClient).to receive(:get).and_return({ status: 'active' }.to_json)
    end

    it 'retrieves the collections status' do
      expect(RestClient).to receive(:get).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}", params: { api_key: ENV['HARVESTER_API_KEY'] })
      worker.send(:source_active?)
    end

    it 'returns true if the collection is active' do
      expect(worker.send(:source_active?)).to be_truthy
    end

    it 'returns false if the collection is suppressed' do
      allow(RestClient).to receive(:get).and_return({ status: 'suppressed' }.to_json)
      expect(worker.send(:source_active?)).to be_falsey
    end
  end

  describe 'get' do
    it 'gets the landing url' do
      expect(RestClient).to receive(:get).with('http://blah.com')
      worker.send(:get, 'http://blah.com')
    end

    it 'handles exceptions by returning nil' do
      response = worker.send(:get, 'http://google.com/unknown')
      expect(response).to be_nil
    end
  end

  describe '#up?' do
    let(:response) { double(:response) }

    context 'HTTP GET returns nil' do
      before { allow(worker).to receive(:get).and_return nil }

      it 'returns false' do
        response = worker.send(:up?, 'http://google.com')
        expect(response).to be_falsey
      end
    end

    it 'gets the url and validates it' do
      allow(worker).to receive(:get).with('http://blah.com').and_return response
      allow(worker).to receive(:validate_link_check_rule).with(response, 'abc123').and_return true

      response = worker.send(:up?, 'http://blah.com')
      expect(response).to be_truthy
    end
  end

  describe '#suppress_collection' do
    before do
      allow(RestClient).to receive(:put)
      mailer = double(deliver: nil)
      allow(CollectionMailer).to receive(:collection_status).with(source, 'suppressed').and_return(mailer)
    end

    it 'suppresses the collection setting the status_updated_by as LINK CHECKER' do
      expect(RestClient).to receive(:put).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}",
source: { status: 'suppressed', status_updated_by: 'LINK CHECKER' }, api_key: ENV['HARVESTER_API_KEY'])
      worker.send(:suppress_collection)
    end

    it 'sends an email that the collection is down' do
      expect(CollectionMailer).to receive(:collection_status).with(source, 'suppressed')
      worker.send(:suppress_collection)
    end
  end

  describe '#activate_collection' do
    before do
      allow(RestClient).to receive(:put)
      mailer = double(deliver: nil)
      allow(CollectionMailer).to receive(:collection_status).with(source, 'activated').and_return(mailer)
    end

    it 'activates the collection and set the status_updated_by as LINK CHECKER' do
      expect(RestClient).to receive(:put).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}",
source: { status: 'active', status_updated_by: 'LINK CHECKER' }, api_key: ENV['HARVESTER_API_KEY'])
      worker.send(:activate_collection)
    end

    it 'sends an email that the collection is down' do
      expect(CollectionMailer).to receive(:collection_status).with(source, 'activated')
      worker.send(:activate_collection)
    end
  end
end
