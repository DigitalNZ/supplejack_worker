# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

Airbrake.configure do |config|
  config.project_key = '55ec146de217fb5c05d235469a4d9279'
  config.project_id = '96483'
  config.ignore_environments = %w(development test)
  config.ignore << 'ThrottleLimitError'
end
