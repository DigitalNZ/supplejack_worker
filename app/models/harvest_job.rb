class HarvestJob
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::SerializerSupport

  field :version,             type: Integer
  field :limit,               type: Integer, default: 0

  field :start_time,          type: DateTime
  field :end_time,            type: DateTime

  field :records_harvested,   type: Integer, default: 0
  field :average_record_time, type: Float
  field :stop,                type: Boolean, default: false
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

  def finished?
    !!end_time
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
