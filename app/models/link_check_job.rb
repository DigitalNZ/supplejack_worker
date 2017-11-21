# frozen_string_literal: true

# The Supplejack Worker code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_worker for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

class LinkCheckJob
  include ActiveModel::ForbiddenAttributesProtection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url,       type: String
  field :record_id, type: Integer
  field :source_id, type: String

  after_create :enqueue

  validates :url, :record_id, :source_id, presence: true

  def source
    Source.find(:all, params: { source: { source_id: source_id } }).first
  end

  private

  def enqueue
    LinkCheckWorker.perform_async(id.to_s) if ENV['LINK_CHECKING_ENABLED'] == 'true'
  end
end
