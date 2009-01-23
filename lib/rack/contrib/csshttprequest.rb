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
      status, headers, body = @app.call(env)
      assembled_body = ""
      body.each { |s| assembled_body << s } # call down the stack
      encoded_response = ::CSSHTTPRequest.encode(assembled_body)
      headers['Content-Length'] = encoded_response.length.to_s
      headers['Content-Type'] = 'text/css'
      [status, headers, encoded_response]
    end
    
  end
end
