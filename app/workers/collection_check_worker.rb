class CollectionCheckWorker
  include Sidekiq::Worker
  include ValidatesResource

  attr_reader :primary_collection

  def perform(primary_collection)
    @primary_collection = primary_collection
    
    collection_up = collection_records.any? {|r| up?(r) }

    suppress_collection if not collection_up and collection_active?
    activate_collection if collection_up and not collection_active?
  end

  private

  def collection_records
    JSON.parse(RestClient.get("#{ENV['API_HOST']}/link_checker/collection_records", {collection: self.primary_collection}))
  end

  def collection_active?
    collection = JSON.parse(RestClient.get("#{ENV['API_HOST']}/link_checker/collection", {collection: self.primary_collection}))
    collection['status'] == "active"
  end

  def get(landing_url)
    RestClient.get(landing_url) rescue nil
  end

  def up?(landing_url)
    if response = get(landing_url)
      validate_collection_rules(response, self.primary_collection)
    end
  end

  def suppress_collection
    RestClient.put("#{ENV['API_HOST']}/link_checker/collection", {collection: self.primary_collection, status: 'suppressed'})
    CollectionMailer.collection_status(self.primary_collection, "down")
  end

  def activate_collection
    RestClient.put("#{ENV['API_HOST']}/link_checker/collection", {collection: self.primary_collection, status: 'active'})
    CollectionMailer.collection_status(self.primary_collection, "up")
  end
end