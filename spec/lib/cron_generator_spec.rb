# frozen_string_literal: true

require 'rails_helper'

describe CronGenerator do
  let(:cron) { CronGenerator.new('weekly') }

  describe '#initialize' do
    it 'at_hour defaults to 0' do
      expect(cron.at_hour).to eq '0'
    end

    it 'at_minutes defaults to 0' do
      expect(cron.at_minutes).to eq '0'
    end

    it 'offset defaults to 0' do
      expect(cron.offset).to eq 0
    end
  end

  describe '#offset' do
    it 'returns a maximum of 6 for weekly' do
      weekly_cron = CronGenerator.new('weekly', nil, nil, 8)
      expect(weekly_cron.offset).to eq 6
    end

    it 'returns a maximum of 13 for fortnightly' do
      fortnightly_cron = CronGenerator.new('fortnightly', nil, nil, 15)
      expect(fortnightly_cron.offset).to eq 13
    end

    it 'returns a maximum of 27 for monthly' do
      monthly_cron = CronGenerator.new('monthly', nil, nil, 30)
      expect(monthly_cron.offset).to eq 27
    end
  end

  describe 'month_day' do
    context 'weekly' do
      it 'returns *' do
        expect(CronGenerator.new('weekly').month_day).to eq '*'
      end
    end

    context 'fortnightly' do
      it 'returns the 1st and 15th without offset' do
        fortnightly_cron = CronGenerator.new('fortnightly')
        expect(fortnightly_cron.month_day).to eq '1,15'
      end

      it 'offsets the fortnightly' do
        fortnightly_cron = CronGenerator.new('fortnightly', nil, nil, 5)
        expect(fortnightly_cron.month_day).to eq '6,20'
      end
    end

    context 'monthly' do
      it 'returns *' do
        monthly_cron = CronGenerator.new('monthly')
        expect(monthly_cron.month_day).to eq '1'
      end

      it 'offsets the day of the month' do
        monthly_cron = CronGenerator.new('monthly', nil, nil, 5)
        expect(monthly_cron.month_day).to eq '6'
      end
    end
  end

  describe 'week_day' do
    context 'weekly' do
      it 'defaults to 0' do
        weekly_cron = CronGenerator.new('weekly')
        expect(weekly_cron.week_day).to eq '0'
      end

      it 'returns the offset' do
        weekly_cron = CronGenerator.new('weekly', nil, nil, 3)
        expect(weekly_cron.week_day).to eq '3'
      end
    end

    context 'monthly' do
      it 'returns *' do
        monthly_cron = CronGenerator.new('monthly')
        expect(monthly_cron.week_day).to eq '*'
      end
    end

    context 'fortnightly' do
      it 'returns *' do
        fortnightly_cron = CronGenerator.new('fortnightly')
        expect(fortnightly_cron.week_day).to eq '*'
      end
    end
  end

  describe 'output' do
    it 'generates a weekly cron on thursdays at 2:30am' do
      weekly_cron = CronGenerator.new('weekly', '2', '30', 4)
      expect(weekly_cron.output).to eq '30 2 * * 4'
    end

    it 'generates a fortnightly cron the 3rd and 17th of the month at 11:30pm' do
      fortnightly_cron = CronGenerator.new('fortnightly', '23', '30', 2)
      expect(fortnightly_cron.output).to eq '30 23 3,17 * *'
    end

    it 'generates a monthly cron on the 7th at 4:50am' do
      monthly_cron = CronGenerator.new('monthly', '4', '50', 6)
      expect(monthly_cron.output).to eq '50 4 7 * *'
    end
  end
end
