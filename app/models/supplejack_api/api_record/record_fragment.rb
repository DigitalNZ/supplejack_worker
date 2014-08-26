# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# Dummy class to access the API record fragment. 
# Needs to be name namespace in order to read the fragment written by the API
class SupplejackApi::ApiRecord::RecordFragment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  embedded_in :record
  delegate :record_id, to: :record

  embeds_many :authorities, cascade_callbacks: true, class_name: "SupplejackApi::Authority"
  embeds_many :locations, cascade_callbacks: true, class_name: "SupplejackApi::Location"

  def relation
    self[:relation]
  end
end