class EnqueueCollectionChecksWorker
  include Sidekiq::Worker

  def perform
    EnqueueCollectionChecksWorker.collections_to_check.each do |collection|
      CollectionCheckWorker.perform_async(collection)
    end
  end

  def self.collections_to_check
    CollectionRules.all.to_a.keep_if{ |rules| rules.active }.map(&:source_id)
  end


end