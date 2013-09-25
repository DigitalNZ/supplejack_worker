class CollectionCheckWorker
  include Sidekiq::Worker
  include ValidatesResource

  attr_reader :source_id

  def perform(source_id)
    @source_id = source_id
    
    collection_up = collection_records.any? {|r| up?(r) }

    suppress_collection if not collection_up and collection_active?
    activate_collection if collection_up and not collection_active?
  end

  private

  def collection_records
    JSON.parse(RestClient.get("#{ENV['API_HOST']}/link_checker/collection_records", {params: {source_id: self.source_id}}))
  end

  def collection_active?
    collection = JSON.parse(RestClient.get("#{ENV['API_HOST']}/link_checker/collection", {params: {source_id: self.source_id}}))
    collection['status'] == "active"
  end

  def get(landing_url)
    RestClient.get(landing_url) rescue nil
  end

  def up?(landing_url)
    if response = get(landing_url)
      validate_collection_rules(response, self.source_id)
    end
  end

  def suppress_collection
    RestClient.put("#{ENV['API_HOST']}/link_checker/collection", {source_id: self.source_id, status: 'suppressed'})
    CollectionMailer.collection_status(self.source_id, "down")
  end

  def activate_collection
    RestClient.put("#{ENV['API_HOST']}/link_checker/collection", {source_id: self.source_id, status: 'active'})
    CollectionMailer.collection_status(self.source_id, "up")
  end
end