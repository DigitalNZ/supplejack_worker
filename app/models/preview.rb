# frozen_string_literal: true

class Preview < ActiveResource::Base
  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  schema do
    attribute :parser_code,            :string
    attribute :parser_id,              :string
    attribute :index,                  :integer
    attribute :user_id,                :string
    attribute :raw_data,               :string
    attribute :harvested_attributes,   :string
    attribute :api_record,             :string
    attribute :status,                 :string
    attribute :deletable,              :boolean
    attribute :field_errors,           :string
    attribute :validation_errors,      :string
    attribute :harvest_failure,        :string
    attribute :harvest_job_errors,     :string
    attribute :format,                 :string
  end

  def spawn_preview_worker
    job = HarvestJob.create(parser_code: parser_code,
                            parser_id: parser_id,
                            environment: 'preview',
                            index: index.to_i,
                            limit: index.to_i + 1,
                            user_id: user_id)

    update_attributes(status: 'New preview record initialised. Waiting in queue...')

    unless job.valid?
      harvest_job = HarvestJob.where(status: 'active', parser_id: job.parser_id,
                                     environment: 'preview').first
      harvest_job.stop!
      job.save!
    end

    PreviewWorker.perform_async(job.id.to_s, id.to_s)

    self
  end

  def id
    self._id
  end
end
