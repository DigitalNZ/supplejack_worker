# frozen_string_literal: true
# Be sure to restart your server when you modify this file.
# This also configures session_options for use below

Rails.application.configure do
  config.session_store :cookie_store, key: '_harvester_worker_session'

  # Required for all session management (regardless of session_store)
  config.middleware.use ActionDispatch::Cookies
  config.middleware.use config.session_store, config.session_options
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# HarvesterWorker::Application.config.session_store :active_record_store
