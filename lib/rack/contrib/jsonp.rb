module Rack

  # A Rack middleware for providing JSON-P support.
  #
  # Full credit to Flinn Mueller (http://actsasflinn.com/) for this contribution.
  #
  class JSONP
    include Rack::Utils
    def initialize(app)
      @app = app
    end

    # Proxies the request to the application, stripping out the JSON-P callback
    # method and padding the response with the appropriate callback format if
    # the returned body is application/json
    #
    # Changes nothing if no <tt>callback</tt> param is specified.
    #
    def call(env)
      status, headers, response = @app.call(env)
      headers = HeaderHash.new(headers)
      request = Rack::Request.new(env)
      
      if is_json?(headers['Content-Type']) && has_callback?(request.params)
        response = pad(request.params.delete('callback'), response)

        # No longer json, its javascript!
        headers['Content-Type'].gsub!('json', 'javascript')
        
        # Set new Content-Length, if it was set before we mutated the response body
        if headers['Content-Length']
          # Code from Rack::ContentLength
          response = [response] if response.respond_to?(:to_str) # rack 0.4 compat
          length = response.to_ary.inject(0) { |len, part| len + bytesize(part) }
          headers['Content-Length'] = length.to_s
        end
      end
      [status, headers, response]
    end
    
    private
    
    def is_json?(header)
      header.include?('application/json')
    end
    
    def has_callback?(params)
      params.include?('callback')
    end

    # Pads the response with the appropriate callback format according to the
    # JSON-P spec/requirements.
    #
    # The Rack response spec indicates that it should be enumerable. The method
    # of combining all of the data into a single string makes sense since JSON
    # is returned as a full string.
    #
    def pad(callback, response, body = "")
      response.each{ |s| body << s.to_s }
      "#{callback}(#{body})"
    end

  end
end
