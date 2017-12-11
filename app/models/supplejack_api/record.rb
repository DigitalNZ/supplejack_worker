# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

module SupplejackApi
  class Record
    include Enrichable

    store_in collection: 'records'

    embeds_many :fragments, cascade_callbacks: true, class_name: 'SupplejackApi::ApiRecord::RecordFragment'

    default_scope -> { where(:status.in => %w[active partial]) }
  end
end
