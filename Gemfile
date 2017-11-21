source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.4'
gem 'puma', '~> 3.7'

gem 'supplejack_common', path: '../supplejack_common'
gem 'oai', git: 'https://github.com/boost/ruby-oai.git'
gem 'active_model_serializers', '~> 0.9.0'
gem 'mongoid'
gem 'mongoid_paranoia'
gem 'figaro'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'aasm'
gem 'airbrake'
gem 'parse-cron'
gem 'sidekiq'
gem 'responders'
gem 'chronic'
gem 'activeresource', require: 'active_resource'
gem 'whenever', require: false

group :test do
  gem 'rspec-rails', '~> 3.6'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'cucumber-rails'
  gem 'timecop'
  gem 'rspec-sidekiq'
end

group :development do
  gem 'pry'
  gem 'pry-byebug'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
