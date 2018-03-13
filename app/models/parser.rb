# frozen_string_literal: true

# app/models/parser.rb
class Parser < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST']
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  def last_harvested_at
    job = harvest_jobs.first
    job ? job.start_time : nil
  end

  def harvest_jobs
    HarvestJob.where(parser_id: id).desc(:start_time)
  end
end
