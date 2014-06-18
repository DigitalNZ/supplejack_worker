# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class Authority
    include Mongoid::Document

    embedded_in :fragment, class_name: 'SupplejackApi::ApiRecord::RecordFragment'

    field :text, type: String
  end
end