# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rails_helper'

describe CollectionStatistics do
  let(:collection_statistics) { FactoryBot.build(:collection_statistics, source_id: 'source_id', day: Date.today) }

  context 'validations' do
    it 'should validate uniqueness of collection name' do
      collection_statistics.save
      collection_stats = FactoryBot.build(:collection_statistics, source_id: 'source_id')
      collection_stats.should_not be_valid
    end

    it 'should validate the uniqueness of day' do
      collection_statistics.save
      collection_stats = FactoryBot.build(:collection_statistics, source_id: 'source_id', day: Date.today)
      collection_stats.should_not be_valid
    end

    it 'should validate presence of collection name' do
      collection_stats = FactoryBot.build(:collection_statistics)
      collection_stats.should_not be_valid
    end

    it 'should validate the presence of day' do
      collection_stats = FactoryBot.build(:collection_statistics, source_id: 'source_id')
      collection_stats.should_not be_valid
    end
  end

  describe '.email_daily_stats' do
    let(:mailer) { double(:mailer) }

    it 'sends daily collection stats' do
      CollectionMailer.should_receive(:daily_collection_stats).with([]) { mailer }
      mailer.should_receive(:deliver)
      CollectionStatistics.email_daily_stats
    end
  end

  describe 'add_record!' do

    before { collection_statistics.save }

    it 'should not try set the collection to an array if the collection does not exist' do
      expect { collection_statistics.add_record!(12, 'bleh', 'http://google.gle')}.to_not raise_error
    end
  end

  describe '.record_id_collection_whitelist' do
    it 'should return the whitelist' do
      CollectionStatistics.send(:record_id_collection_whitelist).should include('suppressed', 'activated', 'deleted')
    end
  end

  describe 'add_record_item' do

    it 'should initialize an empty array if record_ids id nil' do
      collection_statistics.send(:add_record_item, 12345, 'activated', 'http://goog.le/')
      collection_statistics.activated_records.should be_a Array
    end

    it 'should add a record_id to the array of record_ids' do
      collection_statistics.send(:add_record_item, 12345, 'activated', 'http://goog.le')
      collection_statistics.activated_records.should eq [{record_id: 12345, landing_url: 'http://goog.le'}]
    end

    it 'should not reinitialize record_ids array after adding two values' do
      collection_statistics.send(:add_record_item, 12345, 'activated', 'http://goog.le/')
      collection_statistics.send(:add_record_item, 54321, 'activated', 'http://goog.le/1')
      collection_statistics.activated_records.should eq [{record_id: 12345, landing_url: 'http://goog.le/'},{record_id: 54321, landing_url: 'http://goog.le/1'}]
    end

    it 'should not add duplicate items' do
      collection_statistics.send(:add_record_item, 12345, 'activated', 'http://goog.le/')
      collection_statistics.send(:add_record_item, 12345, 'activated', 'http://goog.le/')
      collection_statistics.activated_records.should eq [{record_id: 12345, landing_url: 'http://goog.le/'}]
    end

    it 'should incriment the suppressed_count' do
      collection_statistics.send(:add_record_item, 1234, 'suppressed', 'http://google.gle')
      collection_statistics.suppressed_records.should eq [{record_id: 1234, landing_url: 'http://google.gle'}]
      collection_statistics.suppressed_count.should eq 1
    end

    it 'should only increment for one suppression' do
      collection_statistics.send(:add_record_item, 1234, 'suppressed', 'http://google.gle')
      collection_statistics.send(:add_record_item, 1234, 'suppressed', 'http://google.gle')
      collection_statistics.suppressed_count.should eq 1
    end

    context 'large array of values' do
      context 'activated_records' do
        before do
          (0..19).each { |value| collection_statistics.send(:add_record_item, value, 'activated', 'http://goog.le/')}
          collection_statistics.save
          (20..30).each { |value| collection_statistics.send(:add_record_item, value, 'activated', 'http://goog.le/')}
          collection_statistics.save
        end

        it 'should maintain a size of 20' do
          collection_statistics.reload.activated_records.size.should eq 20
        end

        it 'should have a count of 32' do
          collection_statistics.reload.activated_count.should eq 31
        end
      end

      context 'suppressed_records' do
        before do
          (0..19).each { |value| collection_statistics.send(:add_record_item, value, 'suppressed', 'http://goog.le/')}
          collection_statistics.save
          (20..30).each { |value| collection_statistics.send(:add_record_item, value, 'suppressed', 'http://goog.le/')}
          collection_statistics.save
        end

        it 'should maintain a size of 20' do
          collection_statistics.reload.suppressed_records.size.should eq 20
        end

        it 'should have a count of 32' do
          collection_statistics.reload.suppressed_count.should eq 31
        end
      end

      context 'deleted_records' do
        before do
          (0..19).each { |value| collection_statistics.send(:add_record_item, value, 'deleted', 'http://goog.le/')}
          collection_statistics.save
          (20..30).each { |value| collection_statistics.send(:add_record_item, value, 'deleted', 'http://goog.le/')}
          collection_statistics.save
        end

        it 'should maintain a size of 20' do
          collection_statistics.reload.deleted_records.size.should eq 20
        end

        it 'should have a count of 32' do
          collection_statistics.reload.deleted_count.should eq 31
        end
      end
    end
  end
end
