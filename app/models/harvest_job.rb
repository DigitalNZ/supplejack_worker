class HarvestJob
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::SerializerSupport

  index status: 1

  field :limit,               type: Integer, default: 0
  field :start_time,          type: DateTime
  field :end_time,            type: DateTime
  field :records_harvested,   type: Integer, default: 0
  field :throughput,          type: Float
  field :status,              type: String, default: "active"
  field :user_id,             type: String
  field :parser_id,           type: String
  field :version_id,          type: String
  field :environment,         type: String

  embeds_many :invalid_records
  embeds_many :failed_records
  embeds_one :harvest_failure

  after_create :enqueue
  before_save :calculate_throughput

  def self.search(params)
    search_params = params.try(:dup).try(:symbolize_keys) || {}
    valid_fields = [:status, :environment, :parser_id]

    page = search_params.delete(:page) || 1
    amount = search_params.delete(:limit) || nil

    search_params.delete_if {|key, value| !valid_fields.include?(key) }

    scope = self.page(page.to_i).where(search_params).desc(:start_time)
    scope = scope.limit(amount.to_i) if amount
    scope
  end

  def enqueue
    HarvestWorker.perform_async(self.id)
  end

  def parser
    if version_id.present?
      ParserVersion.find(self.version_id, params: {parser_id: self.parser_id})
    else
      Parser.find(self.parser_id)
    end
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

  def test?
    self.environment == "test"
  end

  def calculate_throughput
    if finished?
      self.throughput = records_harvested.to_f / duration.to_f
    end
  end

  def duration
    return nil unless start_time && end_time
    end_time.to_time - start_time.to_time
  end
end
