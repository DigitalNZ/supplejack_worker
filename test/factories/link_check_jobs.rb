# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :link_check_job do
    url "http://google.co.nz"
    record_id 123
  end
end
