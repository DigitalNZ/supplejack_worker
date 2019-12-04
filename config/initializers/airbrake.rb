# frozen_string_literal: true
if ENV['AIRBRAKE_PROJECT_ID']
  Airbrake.configure do |config|
    config.project_key = ENV['AIRBRAKE_PROJECT_API_KEY']
    config.project_id = ENV['AIRBRAKE_PROJECT_ID']
    config.environment = Rails.env
    config.ignore_environments = %w[development test]
    config.performance_stats = false
  end

  Airbrake.add_filter do |notice|
    # The library supports nested exceptions, so one notice can carry several
    # exceptions.
    if notice[:errors].any? { |error| error[:type] == 'ThrottleLimitError' }
      notice.ignore!
    end
  end
else
  Rails.logger.debug 'The AIRBRAKE_PROJECT_ID ENV Variable has not been set'
end
