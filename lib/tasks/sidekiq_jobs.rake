# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

namespace :sidekiq_jobs do
  desc 'Delets all old jobs from Mongo'
  task purge: :environment do
    AbstractJob.where(:created_at.lte => (Date.today - 7),
                      environment: 'preview').delete_all
    
    AbstractJob.where(:updated_at.lte => (Date.today - 500)).delete_all

    LinkCheckJob.where(:created_at.lte => (Date.today - 7)).delete_all
  end
end

