class ParserVersion < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST'] + "/parsers/:parser_id/"
  self.user = ENV['MANAGER_API_KEY']
  self.element_name = "version"

  def last_harvested_at
    job = self.harvest_jobs[1]
    job ? job.start_time : nil
  end

  def harvest_jobs
    HarvestJob.where(parser_id: self.parser_id).desc(:start_time)
  end

  def parser_id
    @attributes[:parser_id] || @prefix_options[:parser_id]
  end

  def source
    Parser.find(parser_id).source
  end
end