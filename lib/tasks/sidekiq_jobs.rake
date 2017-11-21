# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

namespace :sidekiq_jobs do
  desc 'Delets old jobs from Mongo'
  task purge: :environment do
    # Keeping jobs for last 500 days. These are Harvest Jobs
    AbstractJob.where(:updated_at.lte => (Date.today - 500)).delete_all

    LinkCheckJob.where(:created_at.lte => (Date.today - 7)).delete_all

    AbstractJob.where(:created_at.lte => (Date.today - 7),
                      environment: 'preview').delete_all
  end
end
