# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class SourceCheckWorker
  include Sidekiq::Worker
  include ValidatesResource

  attr_reader :source

  def perform(id)
    @source = Source.find(id)
    
    source_up = source_records.any? {|r| up?(r) }

    suppress_collection if not source_up and source_active?
    activate_collection if source_up and not source_active?
  end

  private

  def source_records
    JSON.parse(RestClient.get("#{ENV['API_HOST']}/sources/#{self.source._id}/link_check_records"))
  end

  def source_active?
    collection = JSON.parse(RestClient.get("#{ENV['API_HOST']}/sources/#{self.source._id}"))
    collection['status'] == "active"
  end

  def get(landing_url)
    RestClient.get(landing_url) rescue nil
  end

  def up?(landing_url)
    if response = get(landing_url)
      validate_link_check_rule(response, self.source._id)
    end
  end

  def suppress_collection
    RestClient.put("#{ENV['API_HOST']}/sources/#{self.source._id}", source: {status: 'suppressed'})
    CollectionMailer.collection_status(self.source.name, "down")
  end

  def activate_collection
    RestClient.put("#{ENV['API_HOST']}/sources/#{self.source._id}", source: {status: 'active'})
    CollectionMailer.collection_status(self.source.name, "up")
  end
end