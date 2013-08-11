require "spec_helper"

describe CollectionCheckWorker do

  let(:worker) { CollectionCheckWorker.new }

  before(:each) do
    worker.instance_variable_set(:@primary_collection, 'Carterton Kete')
    worker.instance_variable_set(:@escaped_primary_collection,'Carterton%20Kete')
  end

  describe "#perform" do
    before(:each) do
      @records = ['http://google.com/1','http://google.com/2']
      worker.stub(:collection_active?) {true}
      worker.stub(:suppress_collection)
    end

    context "setup" do
      before(:each) do
        worker.stub(:collection_records) { [] }
      end

      it "should set the primary_collection instance variable" do
        worker.perform('Carterton Kete')
        worker.instance_variable_get(:@primary_collection).should eq 'Carterton Kete'
      end

      it "should escape the primary_collection as it's used in URLS" do
        ERB::Util.should_receive(:url_encode).with('Carterton Kete') { 'Carterton%20Kete' }
        worker.perform('Carterton Kete')
        worker.instance_variable_get(:@escaped_primary_collection).should eq 'Carterton%20Kete'
      end
    end

    it "should retrieve landing urls from the API to check" do
      worker.stub(:up?) {true}
      worker.should_receive(:collection_records) { @records }
      worker.perform('Carterton Kete')
    end

    it "should check that the records are up" do
      worker.stub(:collection_records) { @records }
      worker.should_receive(:up?).with('http://google.com/1')
      worker.should_receive(:up?).with('http://google.com/2')
      worker.perform('Carterton Kete')
    end

    context "the collection is active and all links are down" do
      before do 
        worker.stub(:collection_active?) {true}
        worker.stub(:collection_records) { @records }
        worker.stub(:up?).with('http://google.com/1') {false}
        worker.stub(:up?).with('http://google.com/2') {false}
      end

      it "should add the collection to the blacklist" do
        worker.should_receive(:suppress_collection)
        worker.perform('Carterton Kete')
      end
    end

    context "the collection is not active and any of the links are up" do
      before do 
        worker.stub(:collection_active?) {false}
        worker.stub(:collection_records) { @records }
        worker.stub(:up?).with('http://google.com/1') {true}
        worker.stub(:up?).with('http://google.com/2') {false}
      end

      it "should remove the collection from the blacklist" do
        worker.should_receive(:activate_collection)
        worker.perform('Carterton Kete')
      end
    end
  end

  describe "collection_records" do

    let(:response) { double(:response) }

    before do
      JSON.stub(:parse) { [] }
      RestClient.stub(:get).with("#{ENV['API_HOST']}/link_checker/collection_records/Carterton%20Kete") { response }
    end

    it "should retrieve landing urls from the API to check" do
      RestClient.should_receive(:get).with("#{ENV['API_HOST']}/link_checker/collection_records/Carterton%20Kete") { response }
      worker.send(:collection_records)
    end

    it "should parse the response" do
      worker.send(:collection_records)
      expect(JSON).to have_received(:parse).with(response)
    end
  end

  describe "collection_active?" do
    before(:each) do
      RestClient.stub(:get) { '{"status":"active"}' }
    end

    it "should retrieve the collections status" do
      RestClient.should_receive(:get).with("#{ENV['API_HOST']}/link_checker/collections/Carterton%20Kete")
      worker.send(:collection_active?)
    end

    it "should return true if the collection is active" do
      worker.send(:collection_active?).should be_true
    end

    it "should return false if the collection is suppressed" do
      RestClient.stub(:get) { '{"status":"suppressed"}' }
      worker.send(:collection_active?).should be_false
    end
  end

  describe "get" do
    it "gets the landing url" do
      RestClient.should_receive(:get).with('http://blah.com')
      worker.send(:get, 'http://blah.com')
    end

    it "handles exceptions by returning nil" do
      worker.send(:get, "http://google.com/unknown").should be_nil
    end
  end

  describe "#up?" do
    let(:response) { double(:response)}

    context "get returns nil" do

      before { worker.stub(:get) { nil } }

      it "returns false" do
        worker.send(:up?,'http://google.com').should be_false
      end
    end
    
    it "gets the url and validates it" do
      worker.should_receive(:get).with('http://blah.com') { response }
      worker.should_receive(:validate_collection_rules).with(response, 'Carterton Kete') { true }
      worker.send(:up?,'http://blah.com').should be_true
    end
  end

  describe "#suppress_collection" do

    before do
      RestClient.stub(:put)
      CollectionMailer.stub(:collection_status).with("Carterton Kete", "down")
    end

    it "should suppress the collection" do
      RestClient.should_receive(:put).with("#{ENV['API_HOST']}/link_checker/collections/Carterton%20Kete", {status: 'suppressed'})
      worker.send(:suppress_collection)
    end

    it "should send an email that the collection is down" do
      worker.send(:suppress_collection)
      expect(CollectionMailer).to have_received(:collection_status).with("Carterton Kete", "down")
    end
  end

  describe "#activate_collection" do

    before do
      RestClient.stub(:put)
      CollectionMailer.stub(:collection_status).with("Carterton Kete", "up")
    end

    it "should suppress the collection" do
      RestClient.should_receive(:put).with("#{ENV['API_HOST']}/link_checker/collections/Carterton%20Kete", {status: 'active'})
      worker.send(:activate_collection)
    end

    it "should send an email that the collection is down" do
      worker.send(:activate_collection)
      expect(CollectionMailer).to have_received(:collection_status).with("Carterton Kete", "up")
    end
  end
end