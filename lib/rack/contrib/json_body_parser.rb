# frozen_string_literal: true

require 'json'

module Rack
  # A Rack middleware that makes JSON-encoded request bodies available in the
  # request.params hash. By default it parses POST, PATCH, and PUT requests
  # whose media type is <tt>application/json</tt>. You can configure it to match
  # any verb or media type via the <tt>:verbs</tt> and <tt>:media</tt> options.
  #
  #
  # == Examples:
  #
  # === Parse POST and GET requests only
  #   use Rack::JSONBodyParser, verbs: ['POST', 'GET']
  #
  # === Parse POST|PATCH|PUT requests whose Content-Type matches 'json'
  #   use Rack::JSONBodyParser, media: /json/
  #
  # === Parse POST requests whose Content-Type is 'application/json' or 'application/vnd+json'
  #   use Rack::JSONBodyParser, verbs: ['POST'], media: ['application/json', 'application/vnd.api+json']
  #
  class JSONBodyParser
    CONTENT_TYPE_MATCHERS = {
      String => lambda { |option, header|
        Rack::MediaType.type(header) == option
      },
      Array => lambda { |options, header|
        media_type = Rack::MediaType.type(header)
        options.any? { |opt| media_type == opt }
      },
      Regexp => lambda {
        if //.respond_to?(:match?)
          # Use Ruby's fast regex matcher when available
          ->(option, header) { option.match? header }
        else
          # Fall back to the slower matcher for rubies older than 2.4
          ->(option, header) { option.match header }
        end
      }.call(),
    }.freeze

    DEFAULT_PARSER = ->(body) { JSON.parse(body, create_additions: false) }

    def initialize(
      app,
      verbs: %w[POST PATCH PUT],
      media: 'application/json',
      &block
    )
      @app = app
      @verbs, @media = verbs, media
      @matcher = CONTENT_TYPE_MATCHERS.fetch(@media.class)
      @parser = block || DEFAULT_PARSER
    end

    def call(env)
      if @verbs.include?(env[Rack::REQUEST_METHOD]) &&
         @matcher.call(@media, env['CONTENT_TYPE'])

        update_form_hash_with_json_body(env)
      end
      @app.call(env)
    rescue JSON::ParserError
      body = { error: 'Failed to parse body as JSON' }.to_json
      header = { 'Content-Type' => 'application/json' }
      Rack::Response.new(body, 400, header).finish
    end

    private

    def update_form_hash_with_json_body(env)
      body = env[Rack::RACK_INPUT]
      return unless (body_content = body.read) && !body_content.empty?

      body.rewind # somebody might try to read this stream
      env.update(
        Rack::RACK_REQUEST_FORM_HASH => @parser.call(body_content),
        Rack::RACK_REQUEST_FORM_INPUT => body
      )
    end
  end
end
