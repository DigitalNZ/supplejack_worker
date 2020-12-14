# frozen_string_literal: true

require 'rails_helper'

describe HarvestSchedule do
  let(:schedule) { HarvestSchedule.new(cron: '* * * * *') }
  let(:time) { Time.parse('2013-02-26 13:30:00') }

  describe 'scope' do
    it 'returns only harvest schedules which are either active or paused' do
      s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: '222', status: 'active')
      s2 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: true, parser_id: '111', status: 'paused')
      s3 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: '333', status: 'inactive')

      expect(HarvestSchedule.all).to eq [s1, s2]
    end
  end

  describe '.one_offs_to_be_run' do
    it 'returns only non recurrent schedules' do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: '222')
        s2 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: true, parser_id: '111')

        expect(HarvestSchedule.one_offs_to_be_run).to eq [s1]
      end
    end

    it 'returns schedules that have start_time in the last 5 minutes' do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: '222')
        s2 = HarvestSchedule.create(start_time: time - 7.minutes, recurrent: false, parser_id: '111')
        expect(HarvestSchedule.one_offs_to_be_run).to eq [s1]
      end
    end

    it 'does not return schedules that have already been run' do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: '222')
        s2 = HarvestSchedule.create(start_time: time - 7.minutes, recurrent: false, parser_id: '111', last_run_at: time - 15.minutes)
        expect(HarvestSchedule.one_offs_to_be_run).to eq [s1]
      end
    end

    it 'does not return schedules that have a start_time in the future' do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: '222')
        s2 = HarvestSchedule.create(start_time: time + 2.minutes, recurrent: false, parser_id: '111')
        expect(HarvestSchedule.one_offs_to_be_run).to eq [s1]
      end
    end
  end

  describe '.create_one_off_jobs' do
    it 'creates a job for every one off schedule that needs to run' do
      expect(HarvestSchedule).to receive(:one_offs_to_be_run).and_return([schedule])
      expect(schedule).to receive(:create_job)
      HarvestSchedule.create_one_off_jobs
    end
  end

  describe '.recurrents_to_be_run' do
    def schedule_with_next_run_at(attributes)
      attributes.reverse_merge!(cron: '* * * * *', recurrent: true, start_time: Time.now - 10.minutes)
      s = HarvestSchedule.create(attributes)
      s.set(next_run_at: attributes[:next_run_at])
      s
    end

    it 'returns only recurrent schedules' do
      Timecop.freeze(time) do
        s1 = schedule_with_next_run_at(parser_id: '222', next_run_at: time - 2.minutes)
        s2 = schedule_with_next_run_at(recurrent: false, parser_id: '111', next_run_at: time - 2.minutes)
        expect(HarvestSchedule.recurrents_to_be_run).to eq [s1]
      end
    end

    it 'returns only schedules with a start_time in the past' do
      Timecop.freeze(time) do
        s1 = schedule_with_next_run_at(start_time: time - 10.minutes, parser_id: '222', next_run_at: time - 2.minutes)
        s2 = schedule_with_next_run_at(start_time: time + 10.minutes, parser_id: '111', next_run_at: time - 2.minutes)
        expect(HarvestSchedule.recurrents_to_be_run).to eq [s1]
      end
    end

    it 'returns only schedules that have a next_run_at in the past' do
      Timecop.freeze(time) do
        s1 = schedule_with_next_run_at(parser_id: '222', next_run_at: time - 1.minutes)
        s2 = schedule_with_next_run_at(parser_id: '111', next_run_at: time + 1.day)
        expect(HarvestSchedule.recurrents_to_be_run).to eq [s1]
      end
    end
  end

  describe '.create_recurrent_jobs' do
    it 'generates jobs for each recurrent schedule' do
      expect(HarvestSchedule).to receive(:recurrents_to_be_run).and_return([schedule])
      expect(schedule).to receive(:create_job)
      HarvestSchedule.create_recurrent_jobs
    end
  end

  describe '#next_job' do
    it 'returns the next time on a weekly cron' do
      Timecop.freeze(time) do
        allow(schedule).to receive(:cron).and_return('0 2 * * 0')
        expect(schedule.next_job).to eq Time.parse('2013-03-03 02:00:00')
      end
    end

    it 'returns the next time on a montly cron' do
      Timecop.freeze(time) do
        allow(schedule).to receive(:cron).and_return('0 2 1 * *')
        expect(schedule.next_job).to eq Time.parse('2013-03-01 02:00:00')
      end
    end

    it 'returns the next time on a fortnightly cron' do
      Timecop.freeze(time) do
        allow(schedule).to receive(:cron).and_return('0 2 1,15 * *')
        expect(schedule.next_job).to eq Time.parse('2013-03-1 02:00:00')
      end
    end

    it 'returns nil when cron is not present' do
      expect(schedule).to receive(:cron).and_return(+'')
      expect(schedule.next_job).to be_nil
    end
  end

  describe '#generate_cron' do
    it 'generates a weekly cron' do
      schedule.frequency = 'weekly'
      schedule.at_hour = '13'
      schedule.at_minutes = '30'
      schedule.offset = 3
      schedule.generate_cron
      expect(schedule.cron).to eq '30 13 * * 3'
    end

    it 'does not generate a cron without a frequency' do
      expect(CronGenerator).to_not receive(:new)
      schedule.frequency = ''
      schedule.generate_cron
    end
  end

  describe '#generate_next_run_at' do
    it 'calculates the next time it should schedule a job' do
      Timecop.freeze(time) do
        allow(schedule).to receive(:next_job).and_return(time)
        schedule.generate_next_run_at
        expect(schedule.next_run_at).to eq time
      end
    end
  end

  describe '#create_job' do
    let(:schedule) { create(:harvest_schedule, parser_id: '1234', environment: 'staging') }

    before do
      allow(schedule).to receive(:allowed?).and_return(true)
    end

    it 'checks if the job is active' do
      allow(schedule).to receive(:active?)
      schedule.create_job
    end

    it 'does not create the job if schedule is not active' do
      allow(schedule).to receive(:active?).and_return(false)
      schedule.create_job
      expect(schedule.harvest_jobs.last).to eq nil
    end

    it 'creates a new harvest job' do
      schedule.create_job
      job = schedule.harvest_jobs.last
      expect(job.parser_id).to eq '1234'
      expect(job.environment).to eq 'staging'
    end

    it 'should update the last_run_at' do
      Timecop.freeze(time) do
        schedule.create_job
        schedule.reload
        expect(schedule.last_run_at).to eq time
      end
    end

    it 'should inactivate one off schedules' do
      schedule.recurrent = false
      schedule.create_job
      schedule.reload
      expect(schedule.status).to eq 'inactive'
    end

    it 'should create a new harvest job with the incremental flag' do
      schedule.mode = 'incremental'
      schedule.create_job
      schedule.reload
      job = schedule.harvest_jobs.last
      expect(job.incremental?).to be_truthy
    end

    it 'should create a new harvest job with enrichments' do
      schedule.enrichments = ['ndha_rights']
      schedule.create_job
      schedule.reload
      job = schedule.harvest_jobs.last
      expect(job.enrichments).to eq ['ndha_rights']
    end
  end

  describe '#allowed' do
    let(:schedule) { create(:harvest_schedule, parser_id: '1234', environment: 'staging') }
    let(:parser) { double(:parser, parser_id: '1234', allow_full_and_flush: true) }

    before do
      allow(Parser).to receive(:find).and_return(parser)
    end

    it 'returns false if full and flush is not allowed' do
      allow(parser).to receive(:allow_full_and_flush).and_return(false)
      expect(schedule.allowed?).to be_falsey
    end

    it 'returns true if full and flush is allowed' do
      expect(schedule.allowed?).to be_truthy
    end
  end
end
