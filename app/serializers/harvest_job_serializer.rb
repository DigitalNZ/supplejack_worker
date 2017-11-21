# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_count, :throughput
  attributes :created_at, :duration, :status, :status_message, :user_id, :parser_id, :version_id, :environment
  attributes :failed_records_count, :invalid_records_count, :harvest_schedule_id, :mode, :posted_records_count, :retried_records_count

  attribute :_type do
    object._type
  end

  has_many :failed_records
  has_many :invalid_records
  has_one :harvest_failure
end
