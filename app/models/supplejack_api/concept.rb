# frozen_string_literal: true
module SupplejackApi
  class Concept
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    store_in client: 'api', collection: 'concepts'

    embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiConcept::ConceptFragment'

    default_scope -> { where(status: 'active') }

    def primary
      fragments.where(priority: 0).first
    end
  end
end
