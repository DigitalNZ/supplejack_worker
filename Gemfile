# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'aasm'
gem 'active_model_serializers', '~> 0.10.7'
gem 'activeresource', require: 'active_resource'
gem 'airbrake', '~> 7.2'
gem 'chronic'
gem 'figaro'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'mongoid', '~> 7.0'
gem 'oai', git: 'https://github.com/boost/ruby-oai.git'
gem 'parse-cron'
gem 'puma', '~> 3.7'
gem 'rails', '5.2.1'
gem 'responders'
gem 'sidekiq', '= 4.1.1'
gem 'sinatra', :require => nil
gem 'supplejack_common', git: 'https://github.com/DigitalNZ/supplejack_common.git', branch: 'rm/sj-elastic-search-scroll-harvest'

gem 'whenever', require: false
gem 'rubocop', require: false

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails', '~> 3.6'
  gem 'rspec-sidekiq'
  gem 'timecop'
  gem 'pry-byebug'
end

group :development do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'pry'
  gem 'pry-byebug'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
