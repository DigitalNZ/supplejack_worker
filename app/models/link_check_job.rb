class LinkCheckJob
  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document
  
  field :url,       type: String
  field :record_id, type: Integer

  after_create :enqueue

  validates :url, :record_id, presence: true

  private

  def enqueue
    LinkCheckWorker.perform_async(self.id)
  end
end
