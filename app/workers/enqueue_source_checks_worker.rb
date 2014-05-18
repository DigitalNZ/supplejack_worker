# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3. 
# See https://github.com/DigitalNZ/supplejack_worker for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class EnqueueSourceChecksWorker
  include Sidekiq::Worker

  def perform
    EnqueueSourceChecksWorker.sources_to_check.each do |collection|
      SourceCheckWorker.perform_async(collection)
    end
  end

  def self.sources_to_check
    LinkCheckRule.all.to_a.keep_if{ |rules| rules.active }.map(&:source_id)
  end


end