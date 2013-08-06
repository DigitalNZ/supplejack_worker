class LinkCheckJob
  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document
  
  field :url,                 type: String
  field :record_id,           type: Integer
  field :primary_collection,  type: String

  after_create :enqueue

  validates :url, :record_id, :primary_collection, presence: true

  private

  def enqueue
    LinkCheckWorker.perform_async(self.id.to_s) if ENV['LINK_CHECKING_ENABLED'].present?
  end
end
