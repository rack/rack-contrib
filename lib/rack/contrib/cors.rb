module Rack
  class CORS
    # Enables Cross Origin Resource Sharing for a list of domains (or domain
    # patterns). Example inputs:
    # ['*'] -- allow all cross domain requests
    # ['http://mysite.com', 'http://localhost:*'] -- allow all requests from mysite and 
    #   any port on localhost
    # ['http://*.mysite.com'] -- allow all requests from any subdomain on localhost
    def initialize(app, domain_patterns = [])
      @app = app
      @@domain_patterns = domain_patterns
    end

    def call(env)
      status, headers, body = @app.call(env)
      # Check the list of domain patterns to see if any match our Origin header.
      # If so, set Access-Control-Allow-Origin to the request's Origin
      origin = env['HTTP_ORIGIN']
      if origin && @@domain_patterns.any? { |pattern| ::File.fnmatch?(pattern, origin) }
        headers['Access-Control-Allow-Origin'] = origin
      end
      [status, headers, body]
    end
  end
end
