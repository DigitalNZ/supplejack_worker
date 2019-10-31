# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.ignore_actions = ['StatusController#index']
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      { msg: 'Request', request: data }
    end
  end

  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:request_id],
      params: event.payload[:params].except('controller', 'action', 'format', 'id'),
      time: event.time
    }
  end

  config.lograge.custom_payload { |controller| { request_id: controller.request.request_id } }
end
