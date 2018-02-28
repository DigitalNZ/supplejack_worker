# frozen_string_literal: true
# Dummy class to access the API record fragment.
# Needs to be name namespace in order to read the fragment written by the API
class SupplejackApi::ApiRecord::RecordFragment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  embedded_in :record
  delegate :record_id, to: :record

  embeds_many :authorities, cascade_callbacks: true, class_name: 'SupplejackApi::Authority'
  embeds_many :locations, cascade_callbacks: true, class_name: 'SupplejackApi::Location'

  def relation
    self[:relation]
  end
end
