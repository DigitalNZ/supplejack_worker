require "spec_helper"

describe LinkCheckWorker do

  let(:worker) { LinkCheckWorker.new }
  let(:link_check_job) { FactoryGirl.create(:link_check_job)  }

  describe "#perform" do
    before do 
      LinkCheckJob.stub(:find) { link_check_job }
      RestClient.stub(:get)
      CollectionRules.stub(:find) { [] }
      worker.stub(:sleep)
    end

    it "should find the link_check_job" do
      LinkCheckJob.should_receive(:find).with(link_check_job.id) { link_check_job }
      worker.perform(link_check_job.id)
    end

    it "should perform a get request with the link_check_job's url" do
      RestClient.should_receive(:get).with(link_check_job.url)
      worker.perform(link_check_job.id)
    end

    it "should supress the record if validate_collection_rules returns false" do
      worker.stub(:validate_collection_rules) { false }
      worker.should_receive(:supress_record).with(link_check_job.record_id)
      worker.perform(link_check_job.id)
    end

    it "should sleep for 2 seconds" do
      worker.should_receive(:sleep).with(2.seconds)
      worker.perform(link_check_job.id)
    end

    context "link check job not found" do
      it "should not check the link" do
        LinkCheckJob.unstub(:find)
        RestClient.should_not_receive(:get)
        worker.perform("anc123")
      end
    end

    context "exceptions" do
      it "should sends a request to the DNZ API updating the status of the record to 'supressed' on a 404 error" do
        RestClient.stub(:get).and_raise(RestClient::ResourceNotFound.new("url not work bro")) 
        RestClient.should_receive(:put).with("#{ENV['API_HOST']}/link_checker/records/#{link_check_job.record_id}", {record: {status: 'supressed'}})
        worker.perform(link_check_job.id)
      end

      it "should handle networking errors" do
        RestClient.stub(:get).and_raise(Exception.new('RestClient Exception'))
        expect {worker.perform(link_check_job.id)}.to_not raise_exception
      end
    end
  end

  describe "#validate_collection_rules" do
    let(:collection_rule) { mock(:collection_rule, status_codes: "200, 3..", xpath: '//p') }

    before { CollectionRules.stub(:find) { [collection_rule] } }

    it "should should find the collection rule" do
      CollectionRules.should_receive(:find).with(:all, params: { collection_rules: { collection_title: link_check_job.primary_collection}}) { [] }
      worker.validate_collection_rules(mock(:response, code: 200), link_check_job.primary_collection)
    end

    it "should validate the response codes" do
      worker.should_receive(:validate_response_codes).with(305, "200, 3..")
      worker.validate_collection_rules(mock(:response, code: 305, body: "<p></p>"), 'TAPUHI')
    end

    it "should validate the response body via xpath" do
      worker.should_receive(:validate_xpath).with("//p", "<p></p>")
      worker.validate_collection_rules(mock(:response, code: 200, body: "<p></p>"), 'TAPUHI')
    end

    context "only response code is invalid" do
      it "should return false" do
        worker.stub(:validate_response_codes) { false }
        worker.stub(:validate_xpath) { true }
        worker.validate_collection_rules(mock(:response, code: 200, body: "<p></p>"), 'TAPUHI').should be_false
      end
    end

    context "only validate xpath is invalid" do
      it "should return false" do
        worker.stub(:validate_response_codes) { true }
        worker.stub(:validate_xpath) { false }
        worker.validate_collection_rules(mock(:response, code: 200, body: "<p></p>"), 'TAPUHI').should be_false
      end
    end
  end
    

  describe "validate_response_codes" do
    it "should return false when the response code matches the string" do
      worker.validate_response_codes(300, '300').should be_false
    end

    it "should return false when the response code matches the regex" do
      worker.validate_response_codes(201, '300, 2..').should be_false
      worker.validate_response_codes(300, '300, 2..').should be_false
    end

    it "should return true if response code blacklist is nil" do
      worker.validate_response_codes(201, nil).should be_true
    end
  end

  describe "#validate_xpath" do
    it "should return false when the xpath expression matches" do
      worker.validate_xpath('//p[@class="error"]', '<p class="error">Page Not Found</p>').should be_false
    end

    it "should return true when the xpath expression doesn't match" do
      worker.validate_xpath('//p[@class="error"]', '<a class="large">Title</a>').should be_true
    end

    it "should return true when there is no xpath" do
      worker.validate_xpath(nil, '<a class="large">Title</a>').should be_true
    end

    it "should return true when there is no xpath" do
      worker.validate_xpath("", '<a class="large">Title</a>').should be_true
    end
  end
end
