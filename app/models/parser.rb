# frozen_string_literal: true

# app/models/parser.rb
class Parser < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"
end
