class LinkCheckRule
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # Note, confusingluy source_id is the mongo id (522e341474544847dd000004) of the source, not the field called source_id (tapuhi)
  field :source_id, type: String
  field :xpath, type: String
  field :status_codes, type: String
  field :active, type: Boolean, default: true
  field :throttle, type: Integer

  validates :source_id, presence: true, uniqueness: true
end