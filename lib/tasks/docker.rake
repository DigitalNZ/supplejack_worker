# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

namespace :docker do
  desc 'Seed data with default user'
  task seed: :environment do
    unless User.where(authentication_token: 'workerkey').first
      user = User.create
      user.authentication_token = 'workerkey'
      user.save
    end
  end
end
