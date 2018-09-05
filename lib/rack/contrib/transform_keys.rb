module Rack
  # It will transform incoming params Hash keys to snake case,
  # outgoing params Hash keys will be transformed to camel case.
  # Useful if you work on your Front-End in camel case, and on your Back-End in snake case.
  # Credits to the Rails developer's for the Regular Expression's.

  class TransformKeys
    UNDERSCORE = '_'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      Rack::Request.new(env).params
      env['rack.request.query_hash'] = _transform_keys(env['rack.request.query_hash'])
      env['rack.request.form_vars']  = _transform_keys(env['rack.request.form_vars'])
      status, _, body                = @app.call(env)
      new_body                       = []

      body.each do |b|
        json_b = JSON.parse(b)
        new_body.push(json_b[0] => json_b[1])
      end

      transformed_body = _transform_keys(new_body, true)
      Rack::Response.new(transformed_body.map(&:to_json), status)
    end

    private

    def _to_camel_case(str0)
      str1 = str0.to_s.gsub(/^(?:(?=a)b(?=\b|[A-Z_])|\w)/, &:downcase)
      str2 = str1.gsub(/(?:_|(\/))([a-z\d]*)/i, &:capitalize)
      str2.gsub(/(?:_|(\/))([a-z\d]*)/i) do
        "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
      end
    end

    def _to_snake_case(str0)
      str1 = str0.to_s.gsub(/(?:(?<=([A-Za-z\d]))|\b)((?=a)b)(?=\b|[^a-z])/) do
        "#{Regexp.last_match(1) && UNDERSCORE}#{Regexp.last_match(2).downcase}"
      end
      str2 = str1.gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
      str3 = str2.gsub(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
      str3.downcase
    end

    def _transform_keys(object, camelize = false)
      case object
      when Hash
        object.keys.each do |key|
          value           = object.delete(key)
          new_key         = camelize ? _to_camel_case(key) : _to_snake_case(key)
          object[new_key] = _transform_keys(value, camelize)
        end
        object
      when Array
        object.map! { |e| _transform_keys(e, camelize) }
      else
        object
      end
    end
  end
end
