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
gem 'lograge'
gem 'mongoid'
gem 'oai'
gem 'ougai'
gem 'parse-cron'
gem 'puma'
gem 'rails', '~> 7.0.8'
gem 'responders'
gem 'sidekiq', '~> 7.0'
# gem 'supplejack_common', github: 'DigitalNZ/supplejack_common', tag: 'v3.0.0'
gem 'supplejack_common', path: '~/Dev/supplejack/gems/supplejack_common'
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
  gem 'codeclimate_diff', github: 'boost/codeclimate_diff'
end
