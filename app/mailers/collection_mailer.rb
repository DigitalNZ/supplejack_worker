class CollectionMailer < ActionMailer::Base
  default from: ENV['LINKCHECKER_EMAIL']
  default to: "example@mail.com"

  def daily_collection_stats(statistics_collections)
  	@statistics_collections = statistics_collections
  	mail(subject: "Daily Link Checker Collection Report For #{Date.today - 1.day} - #{Rails.env.try(:capitalize)}")
  end

  def collection_status(collection, status)
  	@collection, @status = collection, status
  	mail(subject: "#{collection} is #{status}")
  end
end
