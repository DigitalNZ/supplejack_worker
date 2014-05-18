# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class HarvestFailure
  include Mongoid::Document
  include Mongoid::Timestamps

  include ActiveModel::SerializerSupport

  field :exception_class, type: String
  field :message,         type: String
  field :backtrace,       type: Array

  embedded_in :harvest_job
end