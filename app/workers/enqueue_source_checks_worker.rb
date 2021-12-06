# frozen_string_literal: true

# app/workers/enqueue_source_worker.rb
class EnqueueSourceChecksWorker
  include Sidekiq::Job
  sidekiq_options queue: 'default'

  def perform
    time = 0
    EnqueueSourceChecksWorker.sources_to_check.each do |collection|
      SourceCheckWorker.perform_in(time.seconds, collection)
      time += 20
    end
  end

  def self.sources_to_check
    LinkCheckRule.all.to_a.keep_if(&:active).map(&:source_id)
  end
end
