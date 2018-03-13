# frozen_string_literal: true

module SupplejackApi
  # app/models/supplejack_api/location.rb
  class Location
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    embedded_in :fragment, class_name: 'SupplejackApi::ApiRecord::RecordFragment'
  end
end
