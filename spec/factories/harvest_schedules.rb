# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :harvest_schedule do
    start_time "2013-02-26 16:09:29"
    cron "* * * * *"

    environment   "test"
    sequence(:parser_id)  {|n| "abc#{n}" }
  end
end
