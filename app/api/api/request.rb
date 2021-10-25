# frozen_string_literal: true

module Api
  class Request
    attr_reader :url, :token, :params

    def initialize(path, params = {})
      @url = "#{ENV['API_HOST']}#{path}.json"
      @token = ENV['HARVESTER_API_KEY']
      @params = params
    end

    def get
      execute(:get)
    end

    def post
      execute(:post)
    end

    def put
      execute(:put)
    end

    def patch
      execute(:patch)
    end

    def delete
      execute(:delete)
    end

    private
      def execute(method)
        if method.in?(%i[post put patch])
          payload = @params
          url_params = {}
        else
          payload = nil
          url_params = @params
        end

        RestClient::Request.execute(
          method: method,
          url: @url,
          payload: payload,
          headers: {
            'Authentication-Token': @token
          }.merge(url_params)
        )
      end
  end
end
