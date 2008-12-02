module Rack
  
  # A Rack middleware for providing JSON-P support.
  # 
  # Full credit to Flinn Mueller (http://actsasflinn.com/) for this contribution.
  # 
  class JSONP
    
    def initialize(app)
      @app = app
    end
    
    # Proxies the request to the application, stripping out the JSON-P callback
    # method and padding the response with the appropriate callback format.
    # 
    # Changes nothing if no <tt>callback</tt> param is specified.
    # 
    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      response = pad(request.params.delete('callback'), response) if request.params.include?('callback')
      [status, headers, response]
    end
    
    # Pads the response with the appropriate callback format according to the
    # JSON-P spec/requirements.
    # 
    # The Rack response spec indicates that it should be enumerable. The method
    # of combining all of the data into a sinle string makes sense since JSON
    # is returned as a full string.
    # 
    def pad(callback, response, body = "")
      response.each{ |s| body << s }
      "#{callback}(#{body})"
    end
    
  end
end
