module DnzApi
  class Record
    include Mongoid::Document
    
    embeds_many :sources, cascade_callbacks: true, class_name: "DnzApi::Source"

    store_in collection: "records", session: "api"
  end
end