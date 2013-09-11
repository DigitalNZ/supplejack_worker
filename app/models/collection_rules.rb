class CollectionRules
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :source_id, type: String
  field :xpath, type: String
  field :status_codes, type: String
  field :active, type: Boolean, default: true
  field :throttle, type: Integer

  validates :source_id, presence: true, uniqueness: true
end