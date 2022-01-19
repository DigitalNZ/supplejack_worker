# frozen_string_literal: true

# app/models/link_check_job.rb
class LinkCheckJob
  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url,       type: String
  field :record_id, type: Integer
  field :source_id, type: String

  after_create :enqueue

  validates :url, :record_id, :source_id, presence: true
  validate :already_checked?

  def source
    Source.find(source_id)
  rescue ActiveResource::ResourceNotFound
    nil
  end

  private
    def already_checked?
      previous_job = LinkCheckJob.where(record_id: record_id).last

      return unless previous_job

      check_interval = ENV['LINK_CHECKING_INTERVAL'] || 6

      errors.add(:record_id,
                 I18n.t('link_check_job.error', record_id: record_id, check_interval: check_interval)
                ) if (DateTime.now.in_time_zone - previous_job.created_at) / 1.hour < check_interval
    end

    def enqueue
      return unless ENV['LINK_CHECKING_ENABLED'] == 'true'

      LinkCheckWorker.perform_async(id.to_s)
    end
end
