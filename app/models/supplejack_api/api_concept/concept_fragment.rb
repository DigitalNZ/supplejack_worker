# frozen_string_literal: true
# Dummy class to access the API concept fragment.
# Needs to be name namespace in order to read the fragment written by the API
class SupplejackApi::ApiConcept::ConceptFragment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  embedded_in :concept
  delegate :concept_id, to: :concept
end
