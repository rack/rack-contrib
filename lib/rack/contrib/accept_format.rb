module Rack
  #
  # A Rack middleware for automatically adding a <tt>format</tt> token at the end of the request path
  # when there is none. It can detect formats passed in the HTTP_ACCEPT header to populate this token.
  #
  # e.g.:
  #   GET /some/resource HTTP/1.1
  #   Accept: application/json
  # ->
  #   GET /some/resource.json HTTP/1.1
  #   Accept: application/json
  #
  # You can add custom types with this kind of function (taken from sinatra):
  #   def mime(ext, type)
  #     ext = ".#{ext}" unless ext.to_s[0] == ?.
  #     Rack::Mime::MIME_TYPES[ext.to_s] = type
  #   end
  # and then:
  #   mime :json, 'application/json'
  #
  # Note: it does not take into account multiple media types in the Accept header.
  # The first media type takes precedence over all the others.
  #
  # MIT-License - Cyril Rohr
  #
  class AcceptFormat
    # Constants
    DEFAULT_EXTENSION = ".html"

    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      unless req.path_info =~ /(.*)\.(.+)/
        accept = env['HTTP_ACCEPT'].scan(/[^;,\s]*\/[^;,\s]*/)[0] rescue ""
        extension =  Rack::Mime::MIME_TYPES.invert[accept] || DEFAULT_EXTENSION
        req.path_info = req.path_info+"#{extension}"
      end
      @app.call(env)
    end
  end
end
