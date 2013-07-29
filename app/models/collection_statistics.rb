class CollectionStatistics
  include Mongoid::Document
  include Mongoid::Timestamps

  index({collection_title: 1, day: 1}, {unique: true})

  field :collection_title,	          type: String
  field :day,                         type: Date

  field :suppressed_count,            type: Integer, default: 0
  field :deleted_count,               type: Integer, default: 0
  field :activated_count,             type: Integer, default: 0
  
  field :suppressed_records,       type: Array
  field :deleted_records,          type: Array
  field :activated_records,        type: Array

  validates :collection_title, uniqueness: {scope: :day} 
  validates :collection_title, :day, presence: true

  validates :activated_records, :deleted_records, :suppressed_records, length: { maximum: 20 }

  def self.email_daily_stats
    CollectionMailer.daily_collection_stats(CollectionStatistics.where(day: (Date.today - 1.day)).to_a).deliver
  end

  def add_record!(record_id, collection, landing_url)
    return unless self.class.record_id_collection_whitelist.include? collection
    add_record_item(record_id, collection, landing_url)
    self.save
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
      inc("#{collection}_count".to_sym, 1)
    end
  end

end
