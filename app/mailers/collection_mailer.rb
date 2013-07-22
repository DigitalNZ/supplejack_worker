class CollectionMailer < ActionMailer::Base
  default from: ENV['LINKCHECKER_EMAIL']

  def daily_collection_stats(statistics_collections)
  	to_list = "exmaple@mail.com"
  	@statistics_collections = statistics_collections
  	mail(to: to_list, subject: "Daily Link Checker Collection Report For #{Date.today - 1.day} - #{Rails.env.try(:capitalize)}")
  end
end
