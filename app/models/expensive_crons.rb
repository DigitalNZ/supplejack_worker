# frozen_string_literal: true

# This lets worker run scheduled jobs
class ExpensiveCrons
  def self.call
    HarvestSchedule.create_one_off_jobs
    HarvestSchedule.create_recurrent_jobs
    NetworkChecker.check
  end
end
