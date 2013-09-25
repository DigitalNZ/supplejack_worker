# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :collection_rule, :class => 'CollectionRules' do
    source_id "tapuhi"
    xpath "/xpath"
    status_codes "404"
  end
end
