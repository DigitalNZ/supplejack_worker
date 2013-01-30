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

  def enqueue
    HarvestWorker.perform_async(self.id)
  end

  def parser
    Parser.find(self.parser_id)
  end

  def finished?
    !!end_time
  end
end
