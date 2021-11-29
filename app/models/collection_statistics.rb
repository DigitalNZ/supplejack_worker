# frozen_string_literal: true

# app/models/collection_statistics.rb
class CollectionStatistics
  include Mongoid::Document
  include Mongoid::Timestamps

  index({ source_id: 1, day: 1 }, unique: true)
  index({ collection_title: 1, day: 1 }, unique: true)

  field :source_id, type: String
  field :day,                         type: Date

  field :suppressed_count,   type: Integer, default: 0
  field :deleted_count,      type: Integer, default: 0
  field :activated_count,    type: Integer, default: 0
  field :suppressed_records, type: Array
  field :deleted_records,    type: Array
  field :activated_records,  type: Array

  validates :source_id, uniqueness: { scope: :day }
  validates :source_id, :day, presence: true

  validates :activated_records, :deleted_records, :suppressed_records,
            length: { maximum: 20 }

  def self.email_daily_stats
    scope = CollectionStatistics.where(day: (Time.zone.today - 1.day)).to_a
    CollectionMailer.daily_collection_stats(scope).deliver
  end

  def add_record!(record_id, status, landing_url)
    return unless %w[suppressed activated deleted].include? status

    add_record_item(record_id, status, landing_url)
    save!
  end

  private
    def add_record_item(record_id, status, landing_url)
      send("#{status}_records=", []) if send("#{status}_records").nil?

      records = send("#{status}_records")
      record = { record_id: record_id, landing_url: landing_url }
      return if records.include?(record)

      records << record
      inc("#{status}_count".to_sym => 1)
    end
end
