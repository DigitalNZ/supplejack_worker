# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class Concept
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    store_in client: 'api', collection: 'concepts'

    embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiConcept::ConceptFragment'

    default_scope -> { where(status: 'active') }

    def primary
      self.fragments.where(priority: 0).first
    end
  end
end