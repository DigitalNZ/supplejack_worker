class EnqueueSourceChecksWorker
  include Sidekiq::Worker

  def perform
    EnqueueSourceChecksWorker.sources_to_check.each do |collection|
      SourceCheckWorker.perform_async(collection)
    end
  end

  def self.sources_to_check
    LinkCheckRule.all.to_a.keep_if{ |rules| rules.active }.map(&:source_id)
  end


end