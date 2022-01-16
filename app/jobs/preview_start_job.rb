# frozen_string_literal: true

class PreviewStartJob < ApplicationJob
  queue_as :default

  def perform(parser_id)
    @preview = Preview.find(parser_id).spawn_preview_worker
  end
end
