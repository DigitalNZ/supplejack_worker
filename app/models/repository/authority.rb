module Repository
  class Authority
    include Mongoid::Document

    embedded_in :fragment, class_name: "Repository::Fragment"

    field :text, type: String
  end
end