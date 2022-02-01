# frozen_string_literal: true

class Preview < ActiveResource::Base
  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  schema do
    attribute :parser_code,            :string
    attribute :parser_id,              :string
    attribute :index,                  :integer
    attribute :user_id,                :string
    attribute :raw_data,               :string
    attribute :harvested_attributes,   :string
    attribute :api_record,             :string
    attribute :status,                 :string
    attribute :deletable,              :boolean
    attribute :field_errors,           :string
    attribute :validation_errors,      :string
    attribute :harvest_failure,        :string
    attribute :harvest_job_errors,     :string
    attribute :format,                 :string
  end
end
