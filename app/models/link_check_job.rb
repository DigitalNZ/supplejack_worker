class LinkCheckJob
  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document
  
  field :url,                 type: String
  field :record_id,           type: Integer
  field :source_id,  type: String

  after_create :enqueue

  validates :url, :record_id, :source_id, presence: true

  def source
    Source.find(:all, params: {source: {source_id: self.source_id}}).first
  end

  private

  def enqueue
    LinkCheckWorker.perform_async(self.id.to_s) if ENV['LINK_CHECKING_ENABLED'].present?
  end

end
