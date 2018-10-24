# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
# require "active_record/railtie"
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HarvesterWorker
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.eager_load_paths += %W[#{Rails.root}/lib]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.time_zone = 'Wellington'

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    API_HOST = Rails.application.credentials[Rails.env.to_sym][:api_host]
    API_MONGOID_HOSTS = Rails.application.credentials[Rails.env.to_sym][:api_mongoid_hosts]
    MANAGER_HOST = Rails.application.credentials[Rails.env.to_sym][:manager_host]
    HARVESTER_API_KEY = Rails.application.credentials[Rails.env.to_sym][:harvester_api_key]
    HARVESTER_CACHING_ENABLED = Rails.application.credentials[Rails.env.to_sym][:harvester_caching_enabled]
    AIRBRAKE_API_KEY = Rails.application.credentials[Rails.env.to_sym][:airbrake_api_key]
    LINK_CHECKING_ENABLED = Rails.application.credentials[Rails.env.to_sym][:link_checking_enabled]
    LINKCHECKER_RECIPIENTS = Rails.application.credentials[Rails.env.to_sym][:linkchecker_recipients]
    WORKER_KEY = Rails.application.credentials[Rails.env.to_sym][:worker_key]
    MONGOID_STAGING_USER = Rails.application.credential[Rails.env.to_sym][:mongoid_staging_user]
    MONGOID_STAGING_PASSWORD = Rails.application.credentials[Rais.env.to_sym][:mongoid_staging_password]
  end
end

# Setting config.time_zone = 'Wellington'
# within the Application < Rails::Application block
# seems to be overriden back to the default of UTC
# ¯\_(ツ)_/¯
Time.zone = 'Wellington'
