# frozen_string_literal: true
require 'rails_helper'

describe CollectionStatistics do
  let(:collection_statistics) { build(:collection_statistics, source_id: 'source_id', day: Date.today) }

  context 'validations' do
    it 'validates uniqueness of collection name' do
      collection_statistics.save
      collection_stats = build(:collection_statistics, source_id: 'source_id')
      expect(collection_stats).to_not be_valid
    end

    it 'validates the uniqueness of day' do
      collection_statistics.save
      collection_stats = build(:collection_statistics, source_id: 'source_id', day: Date.today)
      expect(collection_stats).to_not be_valid
    end

    it 'validates presence of collection name' do
      collection_stats = build(:collection_statistics)
      expect(collection_stats).to_not be_valid
    end

    it 'validates the presence of day' do
      collection_stats = build(:collection_statistics, source_id: 'source_id')
      expect(collection_stats).to_not be_valid
    end
  end

  describe '.email_daily_stats' do
    let(:mailer) { double(:mailer) }

    it 'sends daily collection stats' do
      allow(CollectionMailer).to receive(:daily_collection_stats).with([]).and_return(mailer)
      allow(mailer).to receive(:deliver)
      allow(CollectionStatistics).to receive(:email_daily_stats)
    end
  end

  describe 'add_record!' do
    before { collection_statistics.save }

    it 'should not try set the collection to an array if the collection does not exist' do
      expect { collection_statistics.add_record!(12, 'bleh', 'http://google.gle') }.to_not raise_error
    end
  end

  describe '.record_id_collection_whitelist' do
    it 'returns the whitelist' do
      expect(CollectionStatistics.send(:record_id_collection_whitelist)).to include 'suppressed', 'activated', 'deleted'
    end
  end

  describe 'add_record_item' do
    it 'initializes an empty array if record_ids id nil' do
      collection_statistics.send(:add_record_item, 12_345, 'activated', 'http://goog.le/')
      expect(collection_statistics.activated_records).to be_a Array
    end

    it 'adds a record_id to the array of record_ids' do
      collection_statistics.send(:add_record_item, 12_345, 'activated', 'http://goog.le')
      expect(collection_statistics.activated_records).to eq [{ record_id: 12_345, landing_url: 'http://goog.le' }]
    end

    it 'does not reinitialize record_ids array after adding two values' do
      collection_statistics.send(:add_record_item, 12_345, 'activated', 'http://goog.le/')
      collection_statistics.send(:add_record_item, 54_321, 'activated', 'http://goog.le/1')
      expect(collection_statistics.activated_records).to eq [{ record_id: 12_345, landing_url: 'http://goog.le/' }, { record_id: 54_321, landing_url: 'http://goog.le/1' }]
    end

    it 'does not add duplicate items' do
      collection_statistics.send(:add_record_item, 12_345, 'activated', 'http://goog.le/')
      collection_statistics.send(:add_record_item, 12_345, 'activated', 'http://goog.le/')
      expect(collection_statistics.activated_records).to eq [{ record_id: 12_345, landing_url: 'http://goog.le/' }]
    end

    it 'does not increment the suppressed_count' do
      collection_statistics.send(:add_record_item, 1234, 'suppressed', 'http://google.gle')
      expect(collection_statistics.suppressed_records).to eq [{ record_id: 1234, landing_url: 'http://google.gle' }]
      expect(collection_statistics.suppressed_count).to eq 1
    end

    it 'only increments for one suppression' do
      collection_statistics.send(:add_record_item, 1234, 'suppressed', 'http://google.gle')
      collection_statistics.send(:add_record_item, 1234, 'suppressed', 'http://google.gle')
      expect(collection_statistics.suppressed_count).to eq 1
    end

    context 'large array of values' do
      context 'activated_records' do
        before do
          (0..19).each { |value| collection_statistics.send(:add_record_item, value, 'activated', 'http://goog.le/') }
          collection_statistics.save
          (20..30).each { |value| collection_statistics.send(:add_record_item, value, 'activated', 'http://goog.le/') }
          collection_statistics.save
        end

        it 'maintains a size of 20' do
          expect(collection_statistics.reload.activated_records.size).to eq 20
        end

        it 'has a count of 31' do
          expect(collection_statistics.reload.activated_count).to eq 31
        end
      end

      context 'suppressed_records' do
        before do
          (0..19).each { |value| collection_statistics.send(:add_record_item, value, 'suppressed', 'http://goog.le/') }
          collection_statistics.save
          (20..30).each { |value| collection_statistics.send(:add_record_item, value, 'suppressed', 'http://goog.le/') }
          collection_statistics.save
        end

        it 'maintains a size of 20' do
          expect(collection_statistics.reload.suppressed_records.size).to eq 20
        end

        it 'has a count of 31' do
          expect(collection_statistics.reload.suppressed_count).to eq 31
        end
      end

      context 'deleted_records' do
        before do
          (0..19).each { |value| collection_statistics.send(:add_record_item, value, 'deleted', 'http://goog.le/') }
          collection_statistics.save
          (20..30).each { |value| collection_statistics.send(:add_record_item, value, 'deleted', 'http://goog.le/') }
          collection_statistics.save
        end

        it 'maintains a size of 20' do
          expect(collection_statistics.reload.deleted_records.size).to eq 20
        end

        it 'has a count of 31' do
          expect(collection_statistics.reload.deleted_count).to eq 31
        end
      end
    end
  end
end
