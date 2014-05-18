# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class CollectionMailer < ActionMailer::Base
  default from: ENV['LINKCHECKER_EMAIL']
  default to: ENV['LINKCHECKER_RECIPIENTS']

  def daily_collection_stats(statistics_collections)
  	@statistics_collections = statistics_collections
  	mail(subject: "Daily Link Checker Collection Report For #{Date.today - 1.day} - #{Rails.env.try(:capitalize)}")
  end

  def collection_status(collection, status)
  	@collection, @status = collection, status
  	mail(subject: "#{collection} is #{status}")
  end
end
