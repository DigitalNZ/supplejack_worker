# frozen_string_literal: true

require 'resolv-replace'
require 'ougai'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  config.log_formatter = Sidekiq::Logger::Formatters::JSON.new
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.strict_args!


# # Uncommment if you need to add HTTP Auth to Sidekiq dashboard
# require 'sidekiq'
# require 'sidekiq/web'

# Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
#   [user, password] == ['username', 'password']
# end
