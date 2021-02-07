# frozen_string_literal: true
#
#

require 'rack'


module CallMeLater
  class Middleware
    attr_reader :endpoint


    def initialize(app, endpoint: nil)
      @app      = app
      @endpoint = endpoint || '/reply_service'
      @hub      = Hub.instance
    end


    def call(env)
      req  = Rack::Request.new(env)
      path = req.path
      id   = req.params['id']

      return @app.call(env) unless path == endpoint

      case @hub.resume(id.to_s.to_sym, req.params)
      in {status: :ok}
        return [
          '200',
          { 'Content-Type' => 'text/plain' },
          ['ok']
        ]

      in {status: :not_found}
        return [
          '404',
          {'Content-Type' => 'text/plain' },
          ['not_found']
        ]
      end
    end
  end
end
