# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestSchedule
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  include ActiveModel::SerializerSupport

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
  field :recurrent,       type: Boolean,  default: true
  field :last_run_at,     type: DateTime, default: nil
  field :next_run_at,     type: DateTime
  field :status,          type: String,   default: "active"
  field :enrichments,     type: Array
  field :mode,            type: String

  before_save :generate_cron
  before_save :generate_next_run_at

  default_scope -> { where(status: "active") }

  scope :one_off, -> { where(recurrent: false).exists(last_run_at: false) }
  scope :recurrent, -> { where(recurrent: true) }

  def self.one_offs_to_be_run
    self.one_off.lte(start_time: Time.now).gte(start_time: Time.now - 6.minutes)
  end

  def self.create_one_off_jobs
    self.one_offs_to_be_run.each(&:create_job)
  end

  def self.recurrents_to_be_run
    self.recurrent.lte(next_run_at: Time.now).lte(start_time: Time.now)
  end

  def self.create_recurrent_jobs
    self.recurrents_to_be_run.each(&:create_job)
  end

  def self.next
    HarvestSchedule.asc(:next_run_at).limit(10)
  end

  def active?
    self.status == "active"
  end

  def next_job
    return nil unless self.cron.present?
    parser = CronParser.new(self.cron)
    parser.next(Time.now)
  end

  def generate_cron
    if self.frequency.present?
      self.cron = CronGenerator.new(frequency, at_hour, at_minutes, offset).output
    end
  end

  def generate_next_run_at
    self.next_run_at = self.next_job
  end

  def create_job
    self.harvest_jobs.create(parser_id: self.parser_id, environment: self.environment, mode: self.mode, enrichments: self.enrichments)
    self.last_run_at = Time.now
    self.status = "inactive" unless self.recurrent
    self.save
  end
end