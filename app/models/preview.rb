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
      data: 'New preview record initialised. Waiting in queue...'
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
end
