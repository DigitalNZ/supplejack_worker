# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}" }

gem 'aasm'
gem 'active_model_serializers', '~> 0.10.7'
gem 'activeresource', require: 'active_resource'
gem 'chronic'
gem 'figaro'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'lograge', '~> 0.11.2'
gem 'mongoid', '~> 7.0'
gem 'oai', '~> 1.1.0' # faraday needs to be updated for 1.2.0
gem 'ougai', '~> 1.8'
gem 'parse-cron'
gem 'puma'
gem 'puma-metrics'
gem 'rails', '~> 7.0.3'
gem 'responders'
gem 'sidekiq', '~> 6.4.0'
gem 'sinatra', require: nil
gem 'supplejack_common', github: 'DigitalNZ/supplejack_common', branch: 'rm/delete-if'
gem 'whenever', require: false
gem 'brakeman'
gem 'amazing_print'
gem 'mimemagic', '= 0.3.10'
gem "rexml", ">= 3.2.5"
gem 'elastic-apm'

# AWS gems required by parsers
gem 'aws-sdk-comprehend', '~> 1.60'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-rekognition', '~> 1.66'

group :test do
  gem 'database_cleaner-mongoid'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'timecop'
end

group :test, :development do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails_config', require: false
  gem 'rubocop-rspec', require: false
end
