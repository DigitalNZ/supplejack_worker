# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe CronGenerator do

  let(:cron) { CronGenerator.new('weekly') }

  describe '#initialize' do
    it 'at_hour should default to 0' do
      cron.at_hour.should eq '0'
    end

    it 'at_minutes should default to 0' do
      cron.at_minutes.should eq '0'
    end

    it 'offset should default to 0' do
      cron.offset.should eq 0
    end
  end

  describe '#offset' do
    it 'should return a maximum of 6 for weekly' do
      CronGenerator.new('weekly', nil, nil, 8).offset.should eq 6
    end

    it 'should return a maximum of 13 for fortnightly' do
      CronGenerator.new('fortnightly', nil, nil, 15).offset.should eq 13
    end

    it 'should return a maximum of 27 for monthly' do
      CronGenerator.new('monthly', nil, nil, 30).offset.should eq 27
    end
  end

  describe 'month_day' do
    context 'weekly' do
      it 'should return *' do
        CronGenerator.new('weekly').month_day.should eq '*'
      end
    end

    context 'fortnightly' do
      it 'should return the 1st and 15th without offset' do
        CronGenerator.new('fortnightly').month_day.should eq '1,15'
      end

      it 'should offset the fortnightly' do
        CronGenerator.new('fortnightly', nil, nil, 5).month_day.should eq '6,20'
      end
    end

    context 'monthly' do
      it 'should return *' do
        CronGenerator.new('monthly').month_day.should eq '1'
      end

      it 'should offest the day of the month' do
        CronGenerator.new('monthly', nil, nil, 5).month_day.should eq '6'
      end
    end
  end

  describe 'week_day' do
    context 'weekly' do
      it 'should default to 0' do
        CronGenerator.new('weekly').week_day.should eq '0'
      end

      it 'should return the offset' do
        CronGenerator.new('weekly', nil, nil, 3).week_day.should eq '3'
      end
    end

    context 'monthly' do
      it 'should return *' do
        CronGenerator.new('monthly').week_day.should eq '*'
      end
    end

    context 'fortnightly' do
      it 'should return *' do
        CronGenerator.new('fortnightly').week_day.should eq '*'
      end
    end
  end

  describe 'output' do
    it 'should generate a weekly cron on thursdays at 2:30am' do
      CronGenerator.new('weekly', '2', '30', 4).output.should eq '30 2 * * 4'
    end

    it 'should generate a fortnightly cron the 3rd and 17th of the month at 11:30pm' do
      CronGenerator.new('fortnightly', '23', '30', 2).output.should eq '30 23 3,17 * *'
    end

    it 'should generate a monthly cron on the 7th at 4:50am' do
      CronGenerator.new('monthly', '4', '50', 6).output.should eq '50 4 7 * *'
    end
  end
end