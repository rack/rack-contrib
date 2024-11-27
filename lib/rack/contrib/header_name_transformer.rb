# frozen_string_literal: true

module Rack
  # Middleware to change the name of a header
  #
  # So, if a server upstream of Rack sends {'X-Header-Name': "value"}
  # you can change header to {'Whatever-You-Want': "value"}
  #
  # There is a specific use case when ensuring the scheme matches when
  # comparing request.origin and request.base_url for CSRF checking,
  # but Rack expects that value to be in the X_FORWARDED_PROTO header.
  #
  # Example Rails usage:
  # If you use a vendor managed proxy or CDN which sends the proto in a header add
  # `config.middleware.use Rack::HeaderNameTransformer, 'Vendor-Forwarded-Proto-Header', 'X-Forwarded-Proto'`
  # to your application.rb file

  class HeaderNameTransformer
    def initialize(app, vendor_header, forwarded_header)
      @app = app
      # Rack expects to see UPPER_UNDERSCORED_HEADERS, never SnakeCased-Dashed-Headers
      @vendor_header = "HTTP_#{vendor_header.upcase.gsub '-', '_'}"
      @forwarded_header = "HTTP_#{forwarded_header.upcase.gsub '-', '_'}"
    end

    def call(env)
      if (value = env[@vendor_header])
        env[@forwarded_header] = value
      end
      @app.call(env)
    end
  end
end
