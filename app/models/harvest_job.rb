class HarvestJob
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::SerializerSupport

  index status: 1

  field :limit,               type: Integer, default: 0
  field :start_time,          type: DateTime
  field :end_time,            type: DateTime
  field :records_harvested,   type: Integer, default: 0
  field :average_record_time, type: Float
  field :status,              type: String, default: "active"
  field :user_id,             type: String
  field :parser_id,           type: String

  embeds_many :harvest_job_errors

  after_create :enqueue
  before_save :calculate_average_record_time

  def enqueue
    HarvestWorker.perform_async(self.id)
  end

  def parser
    Parser.find(self.parser_id)
  end

  def start!
    self.status = "active"
    self.start_time = Time.now
    self.save
  end

  def finish!
    self.status = "finished"
    self.end_time = Time.now
    self.save
  end

  def finished?
    self.status == "finished"
  end

  def stopped?
    self.status == "stopped"
  end

  def calculate_average_record_time
    if finished?
      self.average_record_time = records_harvested.to_f / duration.to_f
    end
  end

  def duration
    return nil unless start_time && end_time
    end_time.to_time - start_time.to_time
  end
end
