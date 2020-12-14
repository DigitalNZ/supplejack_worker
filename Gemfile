# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}" }

gem 'aasm'
gem 'active_model_serializers', '~> 0.10.7'
gem 'activeresource', require: 'active_resource'
gem 'airbrake'
gem 'awesome_print', '~> 1.8'
gem 'aws-sdk-s3', '~> 1'
gem 'chronic'
gem 'figaro'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'lograge', '~> 0.11.2'
gem 'mongoid', '~> 7.0'
gem 'oai'
gem 'ougai', '~> 1.8'
gem 'parse-cron'
gem 'puma'
gem 'rails', '~> 6.0.3'
gem 'responders'
gem 'sidekiq', '~> 5.2.3'
gem 'sinatra', require: nil
gem 'supplejack_common', github: 'DigitalNZ/supplejack_common', tag: 'v2.8.3'
gem 'whenever', require: false
gem 'brakeman'
gem 'moderate_parameters'

group :test do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails', '~> 3.6'
  gem 'rspec-sidekiq'
  gem 'timecop'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test, :development do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails_config', require: false
  gem 'rubocop-rspec', require: false
end
