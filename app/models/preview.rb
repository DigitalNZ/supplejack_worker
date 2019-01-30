# frozen_string_literal: true

# app/models/preview.rb
class Preview
  include Mongoid::Document
  include Mongoid::Timestamps

  field :raw_data,             type: String
  field :harvested_attributes, type: String
  field :api_record,           type: String
  field :status,               type: String
  field :deletable,            type: Boolean
  field :field_errors,         type: String
  field :validation_errors,    type: String
  field :harvest_failure,      type: String
  field :harvest_job_errors,   type: String
  field :format,               type: String

  def self.spawn_preview_worker(attributes)
    job = HarvestJob.create(attributes[:harvest_job])
    preview = Preview.create(format: attributes[:format],
                             status: 'New preview record initialised. Waiting in queue...')

    ActionCable.server.broadcast(
      "preview_channel_#{job.parser_id}_#{job.user_id}",
      status: 'New preview record initialised. Waiting in queue...'
    )

    unless job.valid?
      harvest_job = HarvestJob.where(status: 'active', parser_id: job.parser_id,
                                     environment: 'preview').first
      harvest_job.stop!
      job.save!
    end

    PreviewWorker.perform_async(job.id.to_s, preview.id.to_s)

    preview
  end

  def harvested_attributes_json
    JSON.pretty_generate(JSON.parse(harvested_attributes))
  end

  def api_record_output
    CodeRay.scan(api_record_json, :json).html(line_numbers: :table).html_safe
  end

  def api_record_json
    JSON.pretty_generate(JSON.parse(api_record)) unless api_record.nil?
  end

  def raw_output
    CodeRay.scan(send("pretty_#{format}_output"), format.to_sym).html(line_numbers: :table).html_safe
  end

  def harvested_attributes_output
    CodeRay.scan(harvested_attributes_json, :json).html(:line_numbers => :table).html_safe
  end

  def pretty_xml_output
    raw_data
  end

  def pretty_json_output
    JSON.pretty_generate(JSON.parse(raw_data))
  end

  def field_errors_json
    JSON.pretty_generate(JSON.parse(field_errors)) if field_errors?
  end

  def field_errors?
    JSON.parse(field_errors).any? unless field_errors.nil?
  end

  def field_errors_output
    CodeRay.scan(field_errors_json, :json).html(line_numbers: :table).html_safe if field_errors?
  end

  def harvest_job_errors_output
    JSON.parse(harvest_job_errors) if harvest_job_errors.present?
  end

  def harvest_failure_output
    JSON.parse(harvest_failure) if harvest_failure.present?
  end
end
