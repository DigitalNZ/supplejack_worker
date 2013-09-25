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
    JSON.parse(RestClient.get("#{ENV['API_HOST']}/link_checker/collection_records", {params: {source_id: self.source.source_id}}))
  end

  def source_active?
    collection = JSON.parse(RestClient.get("#{ENV['API_HOST']}/sources/#{self.source._id}.json"))
    collection['status'] == "active"
  end

  def get(landing_url)
    RestClient.get(landing_url) rescue nil
  end

  def up?(landing_url)
    if response = get(landing_url)
      puts "up? response: #{response.code}"
      validate_link_check_rule(response, self.source._id)
    end
  end

  def suppress_collection
    puts self.source.inspect
    RestClient.put("#{ENV['API_HOST']}/sources/#{self.source._id}.json", source: {status: 'suppressed'})
    CollectionMailer.collection_status(self.source.name, "down")
  end

  def activate_collection
    RestClient.put("#{ENV['API_HOST']}/sources/#{self.source._id}.json", source: {status: 'active'})
    CollectionMailer.collection_status(self.source.name, "up")
  end
end