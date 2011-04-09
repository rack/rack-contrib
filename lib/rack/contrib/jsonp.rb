module Rack

  # A Rack middleware for providing JSON-P support.
  #
  # Full credit to Flinn Mueller (http://actsasflinn.com/) for this contribution.
  #
  class JSONP
    include Rack::Utils

    VALID_JS_VAR    = /[a-zA-Z_$][\w$]*/
    VALID_CALLBACK  = /\A#{VALID_JS_VAR}(?:\.?#{VALID_JS_VAR})*\z/

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
      request = Rack::Request.new(env)

      if has_callback?(request)
        callback = request.params['callback']
        return bad_request unless valid_callback?(callback)
      end

      status, headers, response = @app.call(env)

      headers = HeaderHash.new(headers)
      
      if is_json?(headers) && has_callback?(request)
        response = pad(callback, response)

        # No longer json, its javascript!
        headers['Content-Type'] = headers['Content-Type'].gsub('json', 'javascript')
        
        # Set new Content-Length, if it was set before we mutated the response body
        if headers['Content-Length']
          length = response.to_ary.inject(0) { |len, part| len + bytesize(part) }
          headers['Content-Length'] = length.to_s
        end
      end

      [status, headers, response]
    end
    
    private
    
    def is_json?(headers)
      headers.key?('Content-Type') && headers['Content-Type'].include?('application/json')
    end
    
    def has_callback?(request)
      request.params.include?('callback') and not request.params['callback'].empty?
    end

    # See:
    # http://stackoverflow.com/questions/1661197/valid-characters-for-javascript-variable-names
    # 
    # NOTE: Supports dots (.) since callbacks are often in objects:
    # 
    def valid_callback?(callback)
      callback =~ VALID_CALLBACK
    end

    # Pads the response with the appropriate callback format according to the
    # JSON-P spec/requirements.
    #
    # The Rack response spec indicates that it should be enumerable. The
    # method of combining all of the data into a single string makes sense
    # since JSON is returned as a full string.
    #
    def pad(callback, response, body = "")
      return bad_request unless callback =~ //
      response.each{ |s| body << s.to_s }
      ["#{callback}(#{body})"]
    end

    def bad_request(body = "Bad Request")
      [ 400, { 'Content-Type' => 'text/plain', 'Content-Length' => body.size.to_s }, [body] ]
    end

  end
end
