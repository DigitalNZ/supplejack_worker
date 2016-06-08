# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

if ENV['AIRBRAKE_PROJECT_ID']
  Airbrake.configure do |config|
    config.project_key = ENV['AIRBRAKE_PROJECT_API_KEY']
    config.project_id = ENV['AIRBRAKE_PROJECT_ID']
    config.environment = Rails.env
    config.ignore_environments = %w(development test)
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
