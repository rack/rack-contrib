module Rack
  # Automatically sets the Content-Length header on all String bodies
  class ContentLength
    STATUS_WITH_NO_ENTITY_BODY = (100..199).to_a << 204 << 304

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      if !STATUS_WITH_NO_ENTITY_BODY.include?(status) &&
          !headers.has_key?('Content-Length') &&
          body.is_a?(String)
        headers['Content-Length'] = body.length.to_s
      end

      [status, headers, body]
    end
  end
end
