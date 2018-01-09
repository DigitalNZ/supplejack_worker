# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# app/models/snippet_version.rb
#
# FIXME: This model doesn't seems to be used.
# Maybe we are just using the lastest version of snippets.
class SnippetVersion < ActiveResource::Base
  self.site = ENV['MANAGER_HOST'] + '/snippets/:snippet_id/'
  self.element_name = 'version'
  headers['Authorization'] = "Token token=#{ENV['WORKER_KEY']}"


  def snippet_id
    @attributes[:snippet_id] || @prefix_options[:snippet_id]
  end
end
