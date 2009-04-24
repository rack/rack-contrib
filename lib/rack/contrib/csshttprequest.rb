require 'csshttprequest'

module Rack

  # A Rack middleware for providing CSSHTTPRequest responses.
  class CSSHTTPRequest

    def initialize(app)
      @app = app
    end

    # Proxies the request to the application then encodes the response with
    # the CSSHTTPRequest encoder
    def call(env)
      status, headers, response = @app.call(env)
      if chr_request?(env)
        response = encode(response)
        modify_headers!(headers, response)
      end
      [status, headers, response]
    end

    def chr_request?(env)
      env['csshttprequest.chr'] ||=
        !(/\.chr$/.match(env['PATH_INFO'])).nil? || Rack::Request.new(env).params['_format'] == 'chr'
    end

    def encode(response, assembled_body="")
      response.each { |s| assembled_body << s.to_s } # call down the stack
      return ::CSSHTTPRequest.encode(assembled_body)
    end

    def modify_headers!(headers, encoded_response)
      headers['Content-Length'] = encoded_response.length.to_s
      headers['Content-Type'] = 'text/css'
      nil
    end
  end
end
