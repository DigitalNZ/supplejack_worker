# frozen_string_literal: true
module SupplejackApi
  class Authority
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    embedded_in :fragment, class_name: 'SupplejackApi::ApiRecord::RecordFragment'

    field :text, type: String
  end
end
