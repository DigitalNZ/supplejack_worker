# The Supplejack Worker code is Crown copyright (C) 2014,
# New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# This lets worker run scheduled jobs
class ExpensiveCrons
  def self.call
    HarvestSchedule.create_one_off_jobs
    HarvestSchedule.create_recurrent_jobs
    NetworkChecker.check
  end
end
