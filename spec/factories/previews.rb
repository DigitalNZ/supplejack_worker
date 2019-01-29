# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :preview do
    raw_data '{
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON:API paints my bikeshed!",
          "body": "The shortest article. Ever.",
          "created": "2015-05-22T14:56:29.000Z",
          "updated": "2015-05-22T14:56:28.000Z"
        },
        "relationships": {
          "author": {
            "data": {"id": "42", "type": "people"}
          }
        }
      }],
      "included": [
        {
          "type": "people",
          "id": "42",
          "attributes": {
            "name": "John",
            "age": 80,
            "gender": "male"
          }
        }
      ]
    }'
    harvested_attributes '{}'
    api_record '
    {
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON:API paints my bikeshed!",
          "body": "The shortest article. Ever.",
          "created": "2015-05-22T14:56:29.000Z",
          "updated": "2015-05-22T14:56:28.000Z"
        },
        "relationships": {
          "author": {
            "data": {"id": "42", "type": "people"}
          }
        }
      }],
      "included": [
        {
          "type": "people",
          "id": "42",
          "attributes": {
            "name": "John",
            "age": 80,
            "gender": "male"
          }
        }
      ]
    }'
    status 'status'
    deletable false
    field_errors '{}'
    validation_errors 'field_errors'
    harvest_failure 'harvest_failure'
    harvest_job_errors nil
    format 'json'
  end
end
