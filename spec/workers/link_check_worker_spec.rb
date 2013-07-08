require "spec_helper"

describe LinkCheckWorker do

  let(:worker) { LinkCheckWorker.new }
  let(:link_check_job) { FactoryGirl.create(:link_check_job)  }

  describe "#perform" do
    before do 
      LinkCheckJob.stub(:find) { link_check_job }
      RestClient.stub(:get).with(link_check_job.url)
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
end