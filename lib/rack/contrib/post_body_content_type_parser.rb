begin
  require 'json'
rescue LoadError => e
  require 'json/pure'
end

module Rack

  # A Rack middleware for parsing POST/PUT body data when Content-Type is
  # not one of the standard supported types, like <tt>application/json</tt>.
  #
  # TODO: Find a better name.
  #
  class PostBodyContentTypeParser

    # Constants
    #
    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    POST_BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze

    # Supported Content-Types
    #
    APPLICATION_JSON = 'application/json'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      case env[CONTENT_TYPE]
      when APPLICATION_JSON
        env.update(FORM_HASH => JSON.parse(env[POST_BODY].read), FORM_INPUT => env[POST_BODY])
      end
      @app.call(env)
    end

  end
end
