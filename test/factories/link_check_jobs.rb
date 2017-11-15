# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :link_check_job do
    url "http://google.co.nz"
    record_id 123
    source_id 'source_id'
  end
end
