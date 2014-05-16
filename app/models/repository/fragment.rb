# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

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