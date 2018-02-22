# frozen_string_literal: true

require 'rails_helper'

describe SourceCheckWorker do
  let(:worker) { SourceCheckWorker.new }
  let(:source) { double(:source, name: 'name', source_id: 'source_id', id: 'abc123') }

  before(:each) do
    worker.instance_variable_set(:@primary_collection, 'NAME')
    worker.instance_variable_set(:@source, source)
  end

  describe '#perform' do
    before(:each) do
      Source.stub(:find) { source }
      @records = ['http://google.com/1', 'http://google.com/2']
      worker.stub(:source_active?) { true }
      worker.stub(:suppress_collection)
    end

    it 'is a default priority job' do
      expect(worker.sidekiq_options_hash['queue']).to eq 'default'
    end

    it 'should retrieve landing urls from the API to check' do
      worker.stub(:up?) { true }
      worker.should_receive(:source_records) { @records }
      worker.perform('NAME')
    end

    it 'should check that the records are up' do
      worker.stub(:source_records) { @records }
      worker.should_receive(:up?).with('http://google.com/1')
      worker.should_receive(:up?).with('http://google.com/2')
      worker.perform('NAME')
    end

    context 'the collection is active and all links are down' do
      before do
        worker.stub(:source_active?) { true }
        worker.stub(:source_records) { @records }
        worker.stub(:up?).with('http://google.com/1') { false }
        worker.stub(:up?).with('http://google.com/2') { false }
      end

      it 'should add the collection to the blacklist' do
        worker.should_receive(:suppress_collection)
        worker.perform('NAME')
      end
    end

    context 'the collection is not active and any of the links are up' do
      before do
        worker.stub(:source_active?) { false }
        worker.stub(:source_records) { @records }
        worker.stub(:up?).with('http://google.com/1') { true }
        worker.stub(:up?).with('http://google.com/2') { false }
      end

      it 'should remove the collection from the blacklist' do
        worker.should_receive(:activate_collection)
        worker.perform('NAME')
      end
    end
  end

  describe 'source_records' do
    let(:response) { double(:response) }

    before do
      JSON.stub(:parse) { [] }
      RestClient.stub(:get).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}/link_check_records") { response }
    end

    it 'should retrieve landing urls from the API to check' do
      RestClient.should_receive(:get).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}/link_check_records", params: { api_key: ENV['HARVESTER_API_KEY'] }) { response }
      worker.send(:source_records)
    end
  end

  describe 'source_active?' do
    before(:each) do
      RestClient.stub(:get) { '{"status":"active"}' }
    end

    it 'should retrieve the collections status' do
      RestClient.should_receive(:get).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}", params: { api_key: ENV['HARVESTER_API_KEY'] })
      worker.send(:source_active?)
    end

    it 'should return true if the collection is active' do
      worker.send(:source_active?).should be_truthy
    end

    it 'should return false if the collection is suppressed' do
      RestClient.stub(:get) { '{"status":"suppressed"}' }
      worker.send(:source_active?).should be_falsey
    end
  end

  describe 'get' do
    it 'gets the landing url' do
      RestClient.should_receive(:get).with('http://blah.com')
      worker.send(:get, 'http://blah.com')
    end

    it 'handles exceptions by returning nil' do
      worker.send(:get, 'http://google.com/unknown').should be_nil
    end
  end

  describe '#up?' do
    let(:response) { double(:response) }

    context 'get returns nil' do
      before { worker.stub(:get) { nil } }

      it 'returns false' do
        worker.send(:up?, 'http://google.com').should be_falsey
      end
    end

    it 'gets the url and validates it' do
      worker.should_receive(:get).with('http://blah.com') { response }
      worker.should_receive(:validate_link_check_rule).with(response, 'abc123') { true }
      worker.send(:up?, 'http://blah.com').should be_truthy
    end
  end

  describe '#suppress_collection' do
    before do
      RestClient.stub(:put)
      CollectionMailer.stub(:collection_status).with('name', 'down')
    end

    it 'should suppress the collection' do
      RestClient.should_receive(:put).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}", source: { status: 'suppressed' }, api_key: ENV['HARVESTER_API_KEY'])
      worker.send(:suppress_collection)
    end

    it 'should send an email that the collection is down' do
      worker.send(:suppress_collection)
      expect(CollectionMailer).to have_received(:collection_status).with('name', 'down')
    end
  end

  describe '#activate_collection' do
    before do
      RestClient.stub(:put)
      CollectionMailer.stub(:collection_status).with('name', 'up')
    end

    it 'should suppress the collection' do
      RestClient.should_receive(:put).with("#{ENV['API_HOST']}/harvester/sources/#{source.id}", source: { status: 'active' }, api_key: ENV['HARVESTER_API_KEY'])
      worker.send(:activate_collection)
    end

    it 'should send an email that the collection is down' do
      worker.send(:activate_collection)
      expect(CollectionMailer).to have_received(:collection_status).with('name', 'up')
    end
  end
end
