# frozen_string_literal: true

source 'https://rubygems.org'

gem 'aasm'
gem 'active_model_serializers', '~> 0.10.7'
gem 'activeresource', require: 'active_resource'
gem 'airbrake'
gem 'awesome_print', '~> 1.8'
gem 'aws-sdk-s3', '~> 1'
gem 'chronic'
gem 'elastic-apm'
gem 'figaro'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'lograge', '~> 0.11.2'
gem 'mongoid', '~> 7.0'
gem 'oai', git: 'https://github.com/boost/ruby-oai.git'
gem 'ougai', '~> 1.8'
gem 'parse-cron'
gem 'puma', '~> 3.7'
gem 'rails', '5.2.1'
gem 'responders'
gem 'sidekiq', '= 5.2.3'
gem 'sinatra', require: nil
gem 'supplejack_common', git: 'https://github.com/DigitalNZ/supplejack_common.git', tag: 'v2.7.1'
gem 'whenever', require: false

group :test do
  gem 'cucumber-rails', require: false
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
  gem 'rubocop', require: false
end
