# frozen_string_literal: true

# app/models/harvest_schedule.rb
class HarvestSchedule
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :harvest_jobs

  index status: 1

  field :parser_id,       type: String
  field :start_time,      type: DateTime
  field :cron,            type: String
  field :frequency,       type: String
  field :at_hour,         type: Integer
  field :at_minutes,      type: Integer
  field :offset,          type: Integer
  field :environment,     type: String
  field :recurrent,       type: Boolean,  default: false
  field :last_run_at,     type: DateTime, default: nil
  field :next_run_at,     type: DateTime
  field :status,          type: String, default: 'active'
  field :enrichments,     type: Array
  field :mode,            type: String

  before_save :generate_cron
  before_save :generate_next_run_at

  default_scope -> { where(:status.in => %w[active paused stopped]) }

  scope :one_off, -> { where(recurrent: false).exists(last_run_at: false) }
  scope :recurrent, -> { where(recurrent: true) }

  def allowed?
    parser = begin
               Parser.find(parser_id)
             rescue StandardError
               nil
             end
    !!parser&.allow_full_and_flush
  end

  def self.one_offs_to_be_run
    one_off.lte(start_time: Time.zone.now).gte(start_time: Time.zone.now - 6.minutes)
  end

  def self.create_one_off_jobs
    one_offs_to_be_run.each(&:create_job)
  end

  def self.recurrents_to_be_run
    recurrent.lte(next_run_at: Time.zone.now).lte(start_time: Time.zone.now)
  end

  def self.create_recurrent_jobs
    recurrents_to_be_run.each(&:create_job)
  end

  def self.next
    HarvestSchedule.asc(:next_run_at).limit(10)
  end

  def active?
    status == 'active'
  end

  def next_job
    return nil if cron.blank?

    parser = CronParser.new(cron)
    parser.next(Time.zone.now)
  end

  def generate_cron
    return if frequency.blank?
    self.cron = CronGenerator.new(frequency, at_hour, at_minutes, offset).output
  end

  def generate_next_run_at
    self.next_run_at = next_job
  end

  def create_job
    if active?
      harvest_jobs.create(parser_id: parser_id,
                          environment: environment,
                          mode: mode, enrichments: enrichments)

      self.last_run_at = Time.zone.now
      self.status = 'inactive' unless recurrent
    end

    save!
  end
end
