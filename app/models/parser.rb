class Parser < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST']
  self.user = ENV['MANAGER_API_KEY']

  def last_harvested_at
    job = self.harvest_jobs.first
    job ? job.start_time : nil
  end

  def harvest_jobs
    HarvestJob.where(parser_id: self.id).desc(:start_time)
  end
end