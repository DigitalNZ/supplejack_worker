# frozen_string_literal: true
class LinkCheckJob
  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url,       type: String
  field :record_id, type: Integer
  field :source_id, type: String

  after_create :enqueue

  validates :url, :record_id, :source_id, presence: true

  def source
    Source.find(:all, params: { source: { source_id: source_id } }).first
  end

  private

  def enqueue
    LinkCheckWorker.perform_async(id.to_s) if ENV['LINK_CHECKING_ENABLED'] == 'true'
  end
end
