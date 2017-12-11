# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class Source < ActiveResource::Base
  self.site = ENV['MANAGER_HOST']

  schema do
    attribute :name,        				:string
    attribute :partner_id,  				:string
    attribute :source_id,   				:string
    attribute :collection_rules_id, :string
  end
end
