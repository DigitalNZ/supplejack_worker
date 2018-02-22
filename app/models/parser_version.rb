# frozen_string_literal: true
# app/models/parser_version.rb
class ParserVersion < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST'] + '/parsers/:parser_id/'
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  self.element_name = 'version'

  def last_harvested_at
    job = harvest_jobs('finished')[1]
    job ? job.start_time : nil
  end

  def harvest_jobs(status = nil)
    if status == 'finished'
      HarvestJob.where(parser_id: parser_id, status: status).desc(:start_time)
    else
      HarvestJob.where(parser_id: parser_id).desc(:start_time)
    end
  end

  def parser_id
    @attributes[:parser_id] || @prefix_options[:parser_id]
  end

  def source
    Parser.find(parser_id).source
  end

  def concept?
    data_type == 'concept'
  end

  def record?
    data_type == 'record'
  end
end
