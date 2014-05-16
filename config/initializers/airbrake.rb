# The Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']

  config.ignore << 'ThrottleLimitError'
end
