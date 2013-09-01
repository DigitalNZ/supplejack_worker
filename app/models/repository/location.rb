module Repository
  class Location
    include Mongoid::Document

    embedded_in :fragment, class_name: "Repository::Fragment"
  end
end