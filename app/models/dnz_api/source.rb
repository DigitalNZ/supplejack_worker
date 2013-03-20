module DnzApi
  class Source
    include Mongoid::Document

    embedded_in :record, class_name: "DnzApi::Record"
  end
end