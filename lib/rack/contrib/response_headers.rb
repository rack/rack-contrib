# frozen_string_literal: true

module Rack
  # Allows you to tap into the response headers. Yields a Rack::Utils::HeaderHash
  # (Rack 2) or a Rack::Headers (Rack 3) of current response headers to the block.
  # Example:
  #
  #   use Rack::ResponseHeaders do |headers|
  #     headers['X-Foo'] = 'bar'
  #     headers.delete('X-Baz')
  #   end
  #
  class ResponseHeaders
    def initialize(app, &block)
      @app = app
      @block = block
    end

    def call(env)
      response = @app.call(env)
      headers_klass = Rack.release < "3" ? Utils::HeaderHash : Headers
      headers = headers_klass.new.merge(response[1])
      @block.call(headers)
      response[1] = headers
      response
    end
  end
end
