# frozen_string_literal: true

# app/models/abstract_job.rb
class AbstractJob
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include AASM

  index status: 1, start_time: 1, created_at: 1, updated_at: 1, parser_id: 1

  field :start_time,            type: DateTime
  field :end_time,              type: DateTime
  field :updated_at,            type: DateTime
  field :records_count,         type: Integer, default: 0
  field :processed_count,       type: Integer, default: 0
  field :throughput,            type: Float
  field :status,                type: String
  field :status_message,        type: String
  field :user_id,               type: String
  field :parser_id,             type: String
  field :version_id,            type: String
  field :environment,           type: String
  field :invalid_records_count, type: Integer,  default: 0
  field :failed_records_count,  type: Integer,  default: 0
  field :posted_records_count,  type: Integer,  default: 0
  field :parser_code,           type: String
  field :last_posted_record_id, type: String
  field :retried_records,       type: Array, default: []
  field :retried_records_count, type: Integer, default: 0

  embeds_many :invalid_records
  embeds_many :failed_records
  embeds_one :harvest_failure
  embeds_many :states

  belongs_to :harvest_schedule, optional: true

  validates_presence_of   :parser_id, :environment

  scope :disposable, -> { lt(created_at: Time.zone.now - 3.months) }

  def self.search(params)
    search_params = params.to_h.try(:symbolize_keys) || {}
    valid_fields = %i[status environment parser_id]

    page = search_params.delete(:page) || 1
    amount = search_params.delete(:limit) || nil

    search_params.delete_if { |key, _value| !valid_fields.include?(key) }

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
    disposable.each(&:clear_raw_data)
  end

  def enqueue
    raise NotImplementedError, 'All subclasses of AbstractJob must define a #enqueue method.'
  end

  def parser
    return @parser if @parser.present?
    if version_id.present?
      @parser = ParserVersion.find(version_id, params: { parser_id: parser_id })
    elsif environment.present? && !preview?
      version = ParserVersion.find(:one, from: :current, params: { parser_id: parser_id, environment: environment })
      version.parser_id = parser_id
      self.version_id = version.id if version.present?
      @parser = version
    else
      parser = Parser.find(parser_id)
      parser.content = parser_code if parser_code.present?
      @parser = parser
    end
  end

  def required_enrichments
    parser.enrichment_definitions(environment).dup.keep_if do |_name, options|
      options[:required_for_active_record]
    end.keys
  end

  # rubocop:disable Metrics/BlockLength
  aasm column: 'status' do
    state :ready, initial: true
    state :active
    state :finished
    state :failed
    state :stopped

    event :start do
      after do
        self.start_time = Time.zone.now
        self.records_count = 0
        self.processed_count = 0
        save!
      end

      transitions from: :ready, to: :active
    end

    event :finish do
      after do
        self.end_time = Time.zone.now
        calculate_throughput
        calculate_errors_count
        save!
      end

      transitions to: :finished
    end

    # Keep the records count and the posted records count in sync, so that the job knows when to stop.
    # Otherwise jobs will appear finished but stay active forever.
    event :resume do
      after do
        self.records_count = self.posted_records_count
        save!
      end

      transitions to: :active
    end

    event :error do
      after do
        self.start_time = Time.zone.now if start_time.blank?
        self.end_time = Time.zone.now
        calculate_errors_count
        save!
      end

      transitions to: :failed
    end

    event :stop do
      after do
        self.start_time = Time.zone.now if start_time.blank?
        self.end_time = Time.zone.now
        calculate_errors_count
        save!
      end

      transitions to: :stopped
    end
  end
  # rubocop:enable Metrics/BlockLength

  def fail_job(status_message = nil)
    update_attribute(:status_message, status_message) if status_message.present?
    error!
  end

  def test?
    environment == 'test'
  end

  def preview?
    environment == 'preview'
  end

  def calculate_throughput
    return unless duration.to_f.positive?
    self.throughput = records_count.to_f / duration.to_f
  end

  def self.jobs_since(params)
    datetime = Time.zone.parse(params['datetime'])
    AbstractJob.where(:start_time.gte => datetime.getutc,
                      environment: params['environment'],
                      status: params['status'])
  end

  def duration
    return nil unless start_time && end_time
    end_time.to_i - start_time.to_i
  end

  def calculate_errors_count
    self.invalid_records_count = invalid_records.count
    self.failed_records_count = failed_records.count
  end

  def total_errors_count
    invalid_records.count + failed_records.count
  end

  def errors_over_limit?
    total_errors_count > 100
  end

  def clear_raw_data
    invalid_records.destroy_all
    failed_records.destroy_all
  end

  def increment_records_count!
    self.records_count += 1
    save!
  end

  def increment_processed_count!
    self.processed_count += 1
    save!
  end
end
