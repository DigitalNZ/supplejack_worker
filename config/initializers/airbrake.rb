Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']

  # Ignore an error In addition to The defaults
  config.ignore << 'ThrottleLimitError'
end
