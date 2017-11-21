# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe CollectionStatisticsController do

  let(:collection_statistic) { double(:collection_statistics) }
  let(:user) { mock_model(User).as_null_object }

  before(:each) do
    controller.stub(:authenticate_user!) { true }
    controller.stub(:current_user) { user }
  end

  describe 'GET index' do
    it 'should get all of the collection statistics dates' do
      CollectionStatistics.should_receive(:all) { [collection_statistic] }
      get :index
      assigns(:collection_statistics).should eq [collection_statistic]
    end

    it 'should get all of the collection statistics dates' do
      CollectionStatistics.should_receive(:where).with('day' => Date.today.to_s) { [collection_statistic] }
      get :index, params: { collection_statistics: {day: Date.today.to_s} }
      assigns(:collection_statistics).should eq [collection_statistic]
    end
  end
end
