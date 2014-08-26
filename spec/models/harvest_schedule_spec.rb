# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

describe HarvestSchedule do

  let(:schedule) { HarvestSchedule.new(cron: "* * * * *") }
  let(:time) { Time.parse("2013-02-26 13:30:00") }

  describe ".one_offs_to_be_run" do
    it "should only return non recurrent schedules" do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: "222")
        s2 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: true, parser_id: "111")
        HarvestSchedule.one_offs_to_be_run.should eq [s1]
      end
    end

    it "should return schedules that have start_time in the last 5 minutes" do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: "222")
        s2 = HarvestSchedule.create(start_time: time - 7.minutes, recurrent: false, parser_id: "111")
        HarvestSchedule.one_offs_to_be_run.should eq [s1]
      end
    end

    it "should not return schedules that have already been run" do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: "222")
        s2 = HarvestSchedule.create(start_time: time - 7.minutes, recurrent: false, parser_id: "111", last_run_at: time - 15.minutes)
        HarvestSchedule.one_offs_to_be_run.should eq [s1]
      end
    end

    it "should not return schedules that have a start_time in the future" do
      Timecop.freeze(time) do
        s1 = HarvestSchedule.create(start_time: time - 4.minutes, recurrent: false, parser_id: "222")
        s2 = HarvestSchedule.create(start_time: time + 2.minutes, recurrent: false, parser_id: "111")
        HarvestSchedule.one_offs_to_be_run.should eq [s1]
      end
    end
  end

  describe ".create_one_off_jobs" do
    it "should create a job for every one off schedule that needs to run" do
      HarvestSchedule.should_receive(:one_offs_to_be_run) { [schedule] }
      schedule.should_receive(:create_job)
      HarvestSchedule.create_one_off_jobs
    end
  end

  describe ".recurrents_to_be_run" do
    def schedule_with_next_run_at(attributes)
      attributes.reverse_merge!(cron: "* * * * *", recurrent: true, start_time: Time.now - 10.minutes)
      s = HarvestSchedule.create(attributes)
      s.set(next_run_at: attributes[:next_run_at])
      s
    end

    it "returns only recurrent schedules" do
      Timecop.freeze(time) do
        s1 = schedule_with_next_run_at(parser_id: "222", next_run_at: time - 2.minutes)
        s2 = schedule_with_next_run_at(recurrent: false, parser_id: "111", next_run_at: time - 2.minutes)
        HarvestSchedule.recurrents_to_be_run.should eq [s1]
      end
    end

    it "returns only schedules with a start_time in the past" do
      Timecop.freeze(time) do
        s1 = schedule_with_next_run_at(start_time: time - 10.minutes, parser_id: "222", next_run_at: time - 2.minutes)
        s2 = schedule_with_next_run_at(start_time: time + 10.minutes, parser_id: "111", next_run_at: time - 2.minutes)
        HarvestSchedule.recurrents_to_be_run.should eq [s1]
      end
    end

    it "returns only schedules that have a next_run_at in the past" do
      Timecop.freeze(time) do
        s1 = schedule_with_next_run_at(parser_id: "222", next_run_at: time - 1.minutes)
        s2 = schedule_with_next_run_at(parser_id: "111", next_run_at: time + 1.day)
        HarvestSchedule.recurrents_to_be_run.should eq [s1]
      end
    end
  end

  describe ".create_recurrent_jobs" do
    it "should generate jobs for each recurrent schedule" do
      HarvestSchedule.should_receive(:recurrents_to_be_run) { [schedule] }
      schedule.should_receive(:create_job)
      HarvestSchedule.create_recurrent_jobs
    end
  end

  describe "#next_job" do
    it "returns the next time on a weekly cron" do
      Timecop.freeze(time) do
        schedule.stub(:cron) { "0 2 * * 0" }
        schedule.next_job.should eq Time.parse("2013-03-03 02:00:00")
      end
    end

    it "returns the next time on a montly cron" do
      Timecop.freeze(time) do
        schedule.stub(:cron) { "0 2 1 * *" }
        schedule.next_job.should eq Time.parse("2013-03-01 02:00:00")
      end
    end

    it "returns the next time on a fortnightly cron" do
      Timecop.freeze(time) do
        schedule.stub(:cron) { "0 2 1,15 * *" }
        schedule.next_job.should eq Time.parse("2013-03-1 02:00:00")
      end
    end

    it "returns nil when cron is not present" do
      schedule.stub(:cron) { "" }
      schedule.next_job.should be_nil
    end
  end

  describe "#generate_cron" do
    it "generates a weekly cron" do
      schedule.frequency = "weekly"
      schedule.at_hour = "13"
      schedule.at_minutes = "30"
      schedule.offset = 3
      schedule.generate_cron
      schedule.cron.should eq "30 13 * * 3"
    end

    it "should not generate a cron without a frequency" do
      CronGenerator.should_not_receive(:new)
      schedule.frequency = ""
      schedule.generate_cron
    end
  end

  describe "#generate_next_run_at" do
    it "calculates the next time it should schedule a job" do
      Timecop.freeze(time) do
        schedule.stub(:next_job) { time }
        schedule.generate_next_run_at
        schedule.next_run_at.should eq time
      end
    end
  end

  describe "#create_job" do
    let(:schedule) { FactoryGirl.create(:harvest_schedule, parser_id: "1234", environment: "staging") }

    it "should create a new harvest job" do
      schedule.create_job
      job = schedule.harvest_jobs.last
      job.parser_id.should eq "1234"
      job.environment.should eq "staging"
    end

    it "should update the last_run_at" do
      Timecop.freeze(time) do
        schedule.create_job
        schedule.reload
        schedule.last_run_at.should eq time
      end
    end

    it "should inactivate one off schedules" do
      schedule.recurrent = false
      schedule.create_job
      schedule.reload
      schedule.status.should eq "inactive"
    end

    it "should create a new harvest job with the incremental flag" do
      schedule.mode = 'incremental'
      schedule.create_job
      schedule.reload
      job = schedule.harvest_jobs.last
      job.incremental?.should be_true
    end

    it "should create a new harvest job with enrichments" do
      schedule.enrichments = ["ndha_rights"]
      schedule.create_job
      schedule.reload
      job = schedule.harvest_jobs.last
      job.enrichments.should eq ["ndha_rights"]
    end
  end
end