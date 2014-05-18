# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require "spec_helper"

describe NetworkChecker do
  describe "#check" do
    it "should request the Google homepage" do
      RestClient.should_receive(:get).with("http://google.com") { double(:response, code: 200) }
      NetworkChecker.check
    end

    it "should enable link checking if 200 response" do
      ENV["LINK_CHECKING_ENABLED"] = nil
      RestClient.stub(:get) { double(:response, code: 200) }
      NetworkChecker.check
      ENV["LINK_CHECKING_ENABLED"].should eq "true"
    end

    it "should disable link checking on RestClient errors" do
      ENV["LINK_CHECKING_ENABLED"] = "true"
      RestClient.stub(:get).and_raise(RestClient::ResourceNotFound.new("Not found"))
      NetworkChecker.check
      ENV["LINK_CHECKING_ENABLED"].should be_nil
    end
  end
end