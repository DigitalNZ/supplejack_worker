# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/concept.rb
  class Concept
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    index concept_id: 1

    embeds_many :fragments, cascade_callbacks: true,
                            class_name: 'SupplejackApi::ApiConcept::ConceptFragment'

    default_scope -> { where(status: 'active') }

    def primary
      fragments.where(priority: 0).first
    end
  end
end
