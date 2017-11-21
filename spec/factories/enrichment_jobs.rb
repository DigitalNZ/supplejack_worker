# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

FactoryBot.define do
  factory :enrichment_job do
    start_time    Time.now
    environment   'test'
    enrichment    'ndha_rights'
    records_count 100
    posted_records_count 100

    sequence(:parser_id)  {|n| "abc#{n}" }
    sequence(:version_id) {|n| "abc#{n}" }
    sequence(:user_id)    {|n| "abc#{n}" }

    association :harvest_schedule, factory: :harvest_schedule
    association :harvest_job, factory: :harvest_job
  end
end
