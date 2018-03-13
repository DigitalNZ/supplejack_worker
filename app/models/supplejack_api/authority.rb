# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/authority.rb
  class Authority
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    embedded_in :fragment,
                class_name: 'SupplejackApi::ApiRecord::RecordFragment'

    field :text, type: String
  end
end
