# frozen_string_literal: true
class EnqueueSourceChecksWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default'

  def perform
    EnqueueSourceChecksWorker.sources_to_check.each do |collection|
      SourceCheckWorker.perform_async(collection)
    end
  end

  def self.sources_to_check
    LinkCheckRule.all.to_a.keep_if(&:active).map(&:source_id)
  end
end
