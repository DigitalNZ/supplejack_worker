# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

# HarvestScheduleSerializer
class HarvestScheduleSerializer < ActiveModel::Serializer
  attributes :id, :parser_id, :start_time, :cron, :frequency, :at_hour,
             :at_minutes, :offset, :environment, :next_run_at, :last_run_at,
             :recurrent, :mode, :enrichments, :status

  def at_hour
    object.at_hour.to_s.rjust(2, '0')
  end

  def at_minutes
    object.at_minutes.to_s.rjust(2, '0')
  end
end
