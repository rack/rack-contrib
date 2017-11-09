module Rack
  #
  # CAUTION: THIS MIDDLEWARE IS DEPRECATED.  DO NOT USE IT.
  #
  # This middleware is slated for removal as of rack-contrib 2.0.0, because
  # it is terribad.  Applications should *always* use the `Accept` header to
  # detect response formats (when it is available), rather than ignoring
  # that and instead examining the extension of the request.  We recommend
  # using the `rack-accept` gem for handling the `Accept` family of entity
  # request headers.
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
    def self.deprecation_acknowledged
      @deprecation_acknowledged
    end

    def self.acknowledge_deprecation
      @deprecation_acknowledged = true
    end

    def initialize(app, default_extention = '.html')
      unless self.class.deprecation_acknowledged
        warn "Rack::AcceptFormat is DEPRECATED and will be removed in rack-contrib 2.0.0"
        warn "Please see this middleware's documentation for more info."
      end
      @ext = default_extention.to_s.strip
      @ext = ".#{@ext}" unless @ext[0] == ?.
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)

      if ::File.extname(req.path_info).empty?
        accept = env['HTTP_ACCEPT'].to_s.scan(/[^;,\s]*\/[^;,\s]*/)[0].to_s
        extension =  Rack::Mime::MIME_TYPES.invert[accept] || @ext
        req.path_info = req.path_info.chomp('/') << "#{extension}"
      end

      @app.call(env)
    end
  end
end
