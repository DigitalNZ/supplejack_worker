class Source < ActiveResource::Base
	self.site = ENV['MANAGER_HOST']
  self.user = ENV['MANAGER_API_KEY']

  schema do
    attribute :name,        				:string
    attribute :partner_id,  				:string
    attribute :source_id,   				:string
    attribute :collection_rules_id, :string
  end

end