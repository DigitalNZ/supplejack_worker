# frozen_string_literal: true

# app/mailers/collection_mailer.rb
class CollectionMailer < ActionMailer::Base
  default from: ENV['LINKCHECKER_EMAIL']
  default to: ENV['LINKCHECKER_RECIPIENTS']

  def daily_collection_stats(statistics_collections)
    @statistics_collections = statistics_collections
    mail(subject: "Daily Link Checker Collection Report For #{Time.zone.today - 1.day} - #{Rails.env.try(:capitalize)}")
  end

  def collection_status(source, status)
    @source = source
    @status = status
    mail(subject: "#{source.name} is #{status}")
  end
end
