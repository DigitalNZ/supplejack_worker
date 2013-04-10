if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'https://rubygems.org'

gem 'rails', '3.2.12'

#gem "harvester_core", path: "~/dev/harvester-core"
gem "harvester_core", git: "git@scm.digitalnz.org:harvester/core"

gem "oai", git: "https://github.com/code4lib/ruby-oai.git"

gem "active_model_serializers", git: "https://github.com/rails-api/active_model_serializers.git"

gem "thin",         ">= 1.5.0"
gem "mongoid",      "~> 3.0.19"
gem "figaro",       ">= 0.5.0"
gem "devise",       ">= 2.1.2"
gem "kaminari",     "~> 0.14.1"

gem 'honeybadger'
gem "sidekiq"
gem 'slim'
# if you require 'sinatra' you get the DSL extended to Object
gem 'sinatra', :require => nil

gem 'activeresource', require: 'active_resource'

gem 'whenever', :require => false
gem 'parse-cron'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :development do
  gem "quiet_assets",       ">= 1.0.1"
  gem "better_errors",      ">= 0.2.0"
  gem 'guard-rspec'
  gem 'rb-fsevent',         '~> 0.9.1'
end

group :development, :test do
  gem "rspec-rails",        ">= 2.12.2"
  gem "factory_girl_rails", ">= 4.1.0"
end

group :test do
  gem "database_cleaner",   ">= 0.9.1"
  gem "cucumber-rails",     ">= 1.3.0", :require => false
  gem 'timecop'
  gem "rspec-sidekiq"
end
