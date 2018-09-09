module Rack
  #
  # TransformKeys will transform json request param keys to snake case,
  # response json param keys will be transformed to camel case.
  # Useful if you work on your client-side in camel case, and on your server-side in snake case.
  # Credits to the Rails developers for the Regular Expressions.
  #
  #  Example 1,
  #  client sends application/json request with following data:
  #    { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } }
  #
  #  server application will receive the following object:
  #    { 'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' } }
  #
  #  Example 2,
  #  server application renders application/json response with following data:
  #    { 'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' } }
  #
  #  client will receive the following object:
  #    { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } }
  #
  #  Within the Rails framework this could be easily achieved with:
  #    params.deep_transform_keys { |key| key.to_s.underscore }
  #    response_hash.deep_transform_keys { |key| key.to_s.camelize(:lower) }
  #  But not every rack based web application is powered by rails and generally
  #  this shouldn't be done by the application, that's a middleware task.
  #

  class TransformKeys
    UNDERSCORE = '_'.freeze

    # to_camel_case RegEx's
    UPPERCASE_FIRST_LETTER      = /^(?:(?=a)b(?=\b|[A-Z_])|\w)/.freeze
    UNDERSCORE_FOLLOWED_BY_WORD = /(?:_|(\/))([a-z\d]*)/i.freeze

    # to_snake_case RegEx's
    UPPERCASE_FOLLOWED_BY_LOWERCASE_LETTER = /([A-Z\d]+)([A-Z][a-z])/.freeze
    LOWERCASE_FOLLOWED_UPPERCASE_LETTER    = /([a-z\d])([A-Z])/.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      if content_type_json?(env)
        Rack::Request.new(env).params
        if env['rack.request.query_hash'] && env['rack.request.query_hash'].size > 0
          env['rack.request.query_hash'] = transform_keys(env['rack.request.query_hash'])
        elsif env['rack.request.form_hash'] && env['rack.request.form_hash'].size > 0
          env['rack.request.form_hash'] = transform_keys(env['rack.request.form_hash'])
        elsif env['rack.input'] && env['rack.input'].size > 0
          transformed_keys  = transform_keys(parse_json(env['rack.input'].read)).to_json
          env['rack.input'] = StringIO.new(transformed_keys)
        end
      end

      status, header, body = @app.call(env)

      if content_type_json?(header)
        new_body = []
        body.each do |b|
          new_body.push(parse_json(b))
        end
        body = transform_keys(new_body, true).map(&:to_json)
      end
      Rack::Response.new(body, status, header)
    end

    private

    def parse_json(obj)
      JSON.parse(obj)
    rescue JSON::ParserError => e
      raise "JSON Parsing Error! Object seems to be invalid JSON.\n\t#{e}"
    end

    def content_type_json?(obj)
      content_type = obj['Content-Type'] || obj['CONTENT_TYPE']
      content_type && content_type.include?('application/json')
    end

    def to_camel_case(str0)
      str1 = str0.to_s.gsub(UPPERCASE_FIRST_LETTER, &:downcase)
      str2 = str1.gsub(UNDERSCORE_FOLLOWED_BY_WORD, &:capitalize)
      str2.gsub(UNDERSCORE_FOLLOWED_BY_WORD) do
        "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
      end
    end

    def to_snake_case(str0)
      str1 = str0.gsub(UPPERCASE_FOLLOWED_BY_LOWERCASE_LETTER, '\1_\2')
      str2 = str1.gsub(LOWERCASE_FOLLOWED_UPPERCASE_LETTER, '\1_\2')
      str2.downcase
    end

    def transform_keys(object, camelize = false)
      case object
      when Hash
        object.keys.each do |key|
          value           = object.delete(key)
          new_key         = camelize ? to_camel_case(key) : to_snake_case(key)
          object[new_key] = transform_keys(value, camelize)
        end
        object
      when Array
        object.map! { |e| transform_keys(e, camelize) }
      else
        object
      end
    end
  end
end
