begin
  require 'json'
rescue LoadError
  require 'json/pure'
end

module Rack
  # A Rack middleware for making JSON-encoded request bodies available in the
  # request.params hash. By default it parses POST, PATCH, and PUT requests,
  # but you can configure it to parse any request type via the :verbs option
  #
  # Examples:
  #     use Rack::PostBodyContentTypeParser, verbs: %w[POST GET]
  class PostBodyContentTypeParser
    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    DEFAULT_VERBS = %w[POST PATCH PUT].freeze
    JSON_CONTENT_TYPE = /json/.freeze
    DEFAULT_JSON_PARSER = ->(body) { JSON.parse(body, create_additions: false) }

    module Matchers
      # Backport Ruby 2.4's regexp matcher, so Ruby >= 2.4 runs at top speed
      unless ''.respond_to?(:match?)
        refine String do
          def match?(regex)
            self =~ regex
          end
        end
      end

      # env[CONTENT_TYPE] can be nil, so nil must handle #match? in this scope
      refine NilClass do
        def match?(_)
          false
        end
      end
    end

    using Matchers

    def initialize(app, config = {}, &json_parser)
      @app = app
      @verbs = config[:verbs] || DEFAULT_VERBS
      @json_parser = json_parser || DEFAULT_JSON_PARSER
    end

    def call(env)
      if @verbs.include?(env[Rack::REQUEST_METHOD]) &&
         env[CONTENT_TYPE].match?(JSON_CONTENT_TYPE)

        write_json_body_to(env)
      end
      @app.call(env)
    rescue JSON::ParserError
      Rack::Response.new('failed to parse body as JSON', 400).finish
    end

    private

    def write_json_body_to(env)
      body = env[Rack::RACK_INPUT]
      return unless (body_content = body.read) && !body_content.empty?

      body.rewind # somebody might try to read this stream
      env.update(
        Rack::RACK_REQUEST_FORM_HASH => @json_parser.call(body_content),
        Rack::RACK_REQUEST_FORM_INPUT => body
      )
    end
  end
end
