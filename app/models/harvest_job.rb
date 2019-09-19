# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestJob < AbstractJob
  field :limit,                 type: Integer, default: 0
  field :enrichments,           type: Array
  field :index,                 type: Integer
  field :mode,                  type: String, default: 'normal'

  after_create :enqueue, unless: :preview?

  validates_uniqueness_of :parser_id, scope: %i[environment status _type], message: I18n.t('job.already_running', type: 'Harvest'), if: :active?
  validates :mode, inclusion: %w[normal full_and_flush incremental]

  def enqueue
    HarvestWorker.perform_async(id.to_s)
  end

  def enqueue_enrichment_jobs
    parser.enrichment_definitions(environment).each do |name, _options|
      EnrichmentJob.create_from_harvest_job(self, name) if Array(enrichments).include?(name.to_s)
    end
  rescue StandardError, ScriptError => e
    create_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
    fail_job(e.message)
    Airbrake.notify(e, error_message: "Caught Exception. Message:#{e.message}, created harvest failure and failed job")
  end

  def flush_old_records
    RestClient.post("#{ENV['API_HOST']}/harvester/records/flush.json", source_id: source_id, job_id: id, api_key: ENV['HARVESTER_API_KEY'])
  rescue RestClient::Exception => e
    create_harvest_failure(exception_class: e.class, message: "Flush old records failed with the following error mesage: #{e.message}", backtrace: e.backtrace[0..30])
    fail_job(e.message)
    Airbrake.notify(e, error_message: "Flush old records failed with the following error mesage: #{e.message}")
  end

  def records
    start! if may_start?

    options = {}
    options[:limit] = limit.to_i if limit.to_i > 0
    options[:from] = parser.last_harvested_at if incremental? && parser.last_harvested_at

    parser.load_file(environment)
    parser_klass = parser.loader.parser_class
    parser_klass.environment = environment if environment.present?

    parser_klass.records(options).each_with_index do |record, index|
      yield record, index
    end
  rescue StandardError, ScriptError => e
    create_harvest_failure(exception_class: e.class, message: e.message, backtrace: e.backtrace[0..30])
    fail_job(e.message)
    Airbrake.notify(e)
  end

  def source_id
    parser.source.source_id
  end

  def finish!
    flush_old_records if full_and_flush_available?
    super
  end

  def full_and_flush?
    mode == 'full_and_flush'
  end

  def incremental?
    mode == 'incremental'
  end

  def full_and_flush_available?
    full_and_flush? && limit.to_i.zero? && !harvest_failure? && !stopped? && records_count > 0
  end
end
