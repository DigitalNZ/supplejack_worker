class HarvestJob
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::SerializerSupport

  index status: 1

  field :limit,                 type: Integer, default: 0
  field :start_time,            type: DateTime
  field :end_time,              type: DateTime
  field :records_harvested,     type: Integer, default: 0
  field :throughput,            type: Float
  field :status,                type: String, default: "active"
  field :user_id,               type: String
  field :parser_id,             type: String
  field :version_id,            type: String
  field :environment,           type: String
  field :invalid_records_count, type: Integer
  field :failed_records_count,  type: Integer
  field :incremental,           type: Boolean, default: false

  embeds_many :invalid_records
  embeds_many :failed_records
  embeds_one :harvest_failure

  belongs_to :harvest_schedule
  after_create :enqueue

  validates_uniqueness_of :parser_id, scope: [:environment, :status], if: :active?

  scope :disposable, -> { lt(created_at: Time.now-7.days).gt(created_at: Time.now-21.days) }

  def self.search(params)
    search_params = params.try(:dup).try(:symbolize_keys) || {}
    valid_fields = [:status, :environment, :parser_id]

    page = search_params.delete(:page) || 1
    amount = search_params.delete(:limit) || nil

    search_params.delete_if {|key, value| !valid_fields.include?(key) }

    scope = self.page(page.to_i).desc(:start_time)

    search_params.each_pair do |attribute, value|
      if value.is_a?(Array)
        scope = scope.in(attribute => value)
        search_params.delete(attribute)
      end
    end

    scope = scope.where(search_params)
    scope = scope.limit(amount.to_i) if amount
    scope
  end

  def self.clear_raw_data
    self.disposable.each(&:clear_raw_data)
  end

  def enqueue
    HarvestWorker.perform_async(self.id)
  end

  def parser
    if version_id.present?
      ParserVersion.find(self.version_id, params: {parser_id: self.parser_id})
    elsif environment.present?
      version = ParserVersion.find(:one, from: :current, params: {parser_id: self.parser_id, environment: self.environment})
      version.parser_id = self.parser_id
      self.version_id = version.id if version.present?
      version
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
    self.calculate_throughput
    self.calculate_errors_count
    self.save
  end

  def active?
    self.status == "active"
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
    if self.duration.to_f > 0
      self.throughput = self.records_harvested.to_f / self.duration.to_f
    end
  end

  def duration
    return nil unless self.start_time && self.end_time
    self.end_time.to_i - self.start_time.to_i
  end

  def calculate_errors_count
    self.invalid_records_count = self.invalid_records.count
    self.failed_records_count = self.failed_records.count
  end

  def total_errors_count
    self.invalid_records.count + self.failed_records.count
  end

  def errors_over_limit?
    self.total_errors_count > 100
  end

  def clear_raw_data
    self.invalid_records.destroy_all
    self.failed_records.destroy_all
  end
end
