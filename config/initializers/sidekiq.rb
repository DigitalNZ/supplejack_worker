# frozen_string_literal: true

require 'resolv-replace'
require 'ougai'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  Sidekiq.logger = ActiveSupport::TaggedLogging.new(CustomLogger::Logger.new(STDOUT))
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end


# # Uncommment if you need to add HTTP Auth to Sidekiq dashboard
# require 'sidekiq'
# require 'sidekiq/web'

# Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
#   [user, password] == ['username', 'password']
# end
