# frozen_string_literal: true

require 'json'

module Rack
  # A Rack middleware for making JSON-encoded request bodies available in the
  # request.params hash. By default it parses POST, PATCH, and PUT requests,
  # but you can configure it to parse any request type via the :verbs option.
  #
  # Examples:
  #     # parse POST and GET requests only
  #     use Rack::JSONBodyParser, verbs: %w[POST GET]
  #
  #     # parse any request with 'json' in the Content-Type header
  #     use Rack::JSONBodyParser, media_type_matcher: 'loose'
  class JSONBodyParser
    DEFAULT_VERBS = %w[POST PATCH PUT].freeze
    DEFAULT_JSON_PARSER = ->(body) { JSON.parse(body, create_additions: false) }

    def initialize(app, config = {}, &json_parser)
      @app = app
      @verbs = config[:verbs] || DEFAULT_VERBS
      @media_matcher = MediaTypeMatchers.find(config[:media_type_matcher])
      @json_parser = json_parser || DEFAULT_JSON_PARSER
    end

    def call(env)
      if @verbs.include?(env[Rack::REQUEST_METHOD]) && @media_matcher.call(env)

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

    # Strategies for deciding whether a request counts as JSON
    module MediaTypeMatchers
      def self.find(matcher)
        # if the matcher is callable, call it
        return matcher if matcher.respond_to?(:call)

        MATCHERS.fetch(matcher.to_s.to_sym, MATCHERS[:strict])
      end

      # Match any Content-Type header that includes "json"
      module Loose
        # Backport Ruby 2.4's regexp matcher, so Ruby >= 2.4 runs at top speed
        unless ''.respond_to?(:match?)
          refine String do
            def match?(regex)
              self =~ regex
            end
          end
        end

        # env['CONTENT_TYPE'] can be nil, so nil must handle #match?
        refine NilClass do
          def match?(_)
            false
          end
        end

        using self

        def self.call(env)
          env['CONTENT_TYPE'].match?(/json/o)
        end
      end

      # Match only "application/json", "application/json; charset=utf-8", etc
      module Strict
        def self.call(env)
          Rack::MediaType.type(env['CONTENT_TYPE']) == 'application/json'
        end
      end

      MATCHERS = { strict: Strict, loose: Loose }.freeze
    end

    private_constant :MediaTypeMatchers
  end
end
