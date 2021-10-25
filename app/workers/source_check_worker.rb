# frozen_string_literal: true

# app/workers/source_check_worker.rb
class SourceCheckWorker
  include Sidekiq::Worker
  include ValidatesResource
  sidekiq_options queue: 'default'

  attr_reader :source

  def perform(id)
    @source = Source.find(id)

    source_up = source_records.any? { |r| up?(r) }

    suppress_collection if !source_up && source_active?
    activate_collection if source_up && !source_active?
  end

  private
    def source_records
      JSON.parse(
        Api::Source.link_check_records(source.id)
      )
    end

    def source_active?
      collection = JSON.parse(
        Api::Source.get(source.id)
      )
      collection['status'] == 'active'
    end

    def get(landing_url)
      RestClient.get(landing_url)
    rescue StandardError
      nil
    end

    def up?(landing_url)
      return true if landing_url.nil?
      return unless (response = get(landing_url))

      validate_link_check_rule(response, source.id)
    end

    def suppress_collection
      Api::Source.put(source.id, source:
        { status: 'suppressed', status_updated_by: 'LINK CHECKER' }
      )
      CollectionMailer.collection_status(source, 'suppressed').deliver
    end

    def activate_collection
      Api::Source.put(source.id, source:
        { status: 'active', status_updated_by: 'LINK CHECKER' }
      )
      CollectionMailer.collection_status(source, 'activated').deliver
    end
end
