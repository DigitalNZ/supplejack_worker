# frozen_string_literal: true
module SupplejackApi
  class Location
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    embedded_in :fragment, class_name: 'SupplejackApi::ApiRecord::RecordFragment'
  end
end
