# frozen_string_literal: true

# app/models/parser_version.rb
class ParserVersion < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST'] + '/parsers/:parser_id/'
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"

  self.element_name = 'version'

  def last_harvested_at
    last_finished_harvest_job = HarvestJob.desc(:start_time)
                                          .find_by(
                                            parser_id: parser_id,
                                            status: 'finished',
                                            environment: { '$ne': 'preview' }
                                          )

    last_finished_harvest_job.start_time
  rescue Mongoid::Errors::DocumentNotFound
    nil
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
