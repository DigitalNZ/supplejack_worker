# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class ParserVersion < ActiveResource::Base
  include ParserLoaderHelpers

  self.site = ENV['MANAGER_HOST'] + '/parsers/:parser_id/'
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
