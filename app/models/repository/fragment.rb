module Repository
  class Fragment
    include Mongoid::Document

    embedded_in :record, class_name: "Repository::Record"

    embeds_many :authorities, cascade_callbacks: true, class_name: "Repository::Authority"
    embeds_many :locations, cascade_callbacks: true, class_name: "Repository::Location"

    def relation
    	self[:relation]
    end
  end
end