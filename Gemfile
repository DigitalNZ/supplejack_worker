# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'https://rubygems.org'

gem 'supplejack_common', git: 'git@github.com:DigitalNZ/supplejack_common.git'

gem 'rails', '4.1.4'
gem 'protected_attributes'
gem 'oai', git: 'https://github.com/boost/ruby-oai.git'
gem 'active_model_serializers', '~> 0.9.0'
gem 'thin',         '>= 1.5.0'
gem 'mongoid',      '~> 4.0.0'
gem 'mongoid_paranoia'
gem 'figaro',       '>= 0.7.0'
gem 'devise',       '~> 3.0.4'
gem 'kaminari',     '~> 0.14.1'
gem 'airbrake'
gem 'aasm',         '~> 3.3.3'
gem 'sidekiq',      '~> 2.15.0'
# if you require 'sinatra' you get the DSL extended to Object
gem 'sinatra', :require => nil
gem 'activeresource', require: 'active_resource'
gem 'whenever', :require => false
gem 'parse-cron'
gem 'jquery-rails'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 4.0.3'
  gem 'coffee-rails', '~> 4.0.1'
  gem 'therubyracer', :platforms => :ruby
  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem 'quiet_assets',       '>= 1.0.1'
  gem 'better_errors',      '~> 1.1.0 '
  gem 'guard-rspec'
  gem 'rb-fsevent',         '~> 0.9.1'
  gem 'pry-rails'
end

group :development, :test do
  gem 'rspec', '~> 2.14.0'
  gem 'rspec-rails', '~> 2.14.0'
  gem 'factory_girl_rails', '>= 4.1.0'
  gem 'debugger'
end

group :test do
  gem 'database_cleaner',   '~> 1.3.0'
  gem 'cucumber-rails',     '>= 1.4.1', :require => false
  gem 'timecop'
  gem 'rspec-sidekiq'
end
