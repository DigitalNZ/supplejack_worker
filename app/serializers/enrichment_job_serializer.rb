# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class EnrichmentJobSerializer < ActiveModel::Serializer

  attributes :id, :start_time, :end_time, :records_count, :throughput
  attributes :created_at, :duration, :status, :status_message, :user_id, :parser_id, :version_id, :environment, :enrichment
  attributes :posted_records_count, :processed_count, :record_id

  attribute :_type do
    object._type
  end
end