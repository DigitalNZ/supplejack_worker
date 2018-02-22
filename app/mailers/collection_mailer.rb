# frozen_string_literal: true
class CollectionMailer < ActionMailer::Base
  default from: ENV['LINKCHECKER_EMAIL']
  default to: ENV['LINKCHECKER_RECIPIENTS']

  def daily_collection_stats(statistics_collections)
    @statistics_collections = statistics_collections
    mail(subject: "Daily Link Checker Collection Report For #{Date.today - 1.day} - #{Rails.env.try(:capitalize)}")
  end

  def collection_status(collection, status)
    @collection = collection
    @status = status
    mail(subject: "#{collection} is #{status}")
  end
end
