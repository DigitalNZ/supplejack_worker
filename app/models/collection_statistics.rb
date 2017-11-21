# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class CollectionStatistics
  include Mongoid::Document
  include Mongoid::Timestamps

  index({source_id: 1, day: 1}, {unique: true})
  index({collection_title: 1, day: 1}, {unique: true})
  #db.collection_statistics.ensureIndex( { "day": 1 }, { expireAfterSeconds: 2592000 } )

  field :source_id,	          type: String
  field :day,                         type: Date

  field :suppressed_count,            type: Integer, default: 0
  field :deleted_count,               type: Integer, default: 0
  field :activated_count,             type: Integer, default: 0
  
  field :suppressed_records,       type: Array
  field :deleted_records,          type: Array
  field :activated_records,        type: Array

  validates :source_id, uniqueness: {scope: :day} 
  validates :source_id, :day, presence: true

  validates :activated_records, :deleted_records, :suppressed_records, length: { maximum: 20 }

  def self.email_daily_stats
    CollectionMailer.daily_collection_stats(CollectionStatistics.where(day: (Date.today - 1.day)).to_a).deliver
  end

  def add_record!(record_id, collection, landing_url)
    return unless self.class.record_id_collection_whitelist.include? collection
    add_record_item(record_id, collection, landing_url)
    self.save!
  end

  private

  def self.record_id_collection_whitelist
    ["suppressed", "activated", "deleted"]
  end

  def add_record_item(record_id, collection, landing_url)
  	self.send("#{collection}_records=", []) if self.send("#{collection}_records").nil?

    records = self.send("#{collection}_records")
    record = {record_id: record_id, landing_url: landing_url}
    unless records.include?(record)
    	records << record
      inc("#{collection}_count".to_sym => 1)
    end
  end

end
