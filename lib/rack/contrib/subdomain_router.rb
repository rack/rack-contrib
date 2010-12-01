module Rack
  #
  # A Rack middleware for handling subdomains using a simple regex
  # routing table.  Useful for handling wildcard subdomains.
  #
  # If a request matches one of the subdomains defined by your regex,
  # it is passed to the app defined in the routing table.
  #
  # Otherwise, the request is just handled by your main app.
  #
  # e.g.:
  #
  #  sub1 =  lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from sub1!"]] }
  #  sub2 = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from sub2!"]] }
  #  www = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from www!"]] }
  #
  #  app = Rack::Builder.new do
  #
  #    use Rack::SubdomainRouter, "test.com",
  #    {
  #      /^(www\.)?(sub1)/ => sub1,
  #      /^sub2/ => sub2,
  #      /^www/ => www
  #    }
  #
  #      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from default!"]] }
  #  end
  #
  # MIT-License - Matt Murphy
  #
  class SubdomainRouter
    def initialize(app, base_url, routes)
      @app = app
      @routes = routes
      @base_url = base_url
    end

    def call(env)
      subdomain = env['SERVER_NAME'].gsub(@base_url, '').strip.downcase
      match = nil
      @routes.keys.each do |r|
        if subdomain =~ r
          match = r ; break
        else
          match = nil
        end
      end
      if  match
        @routes[match].call(env)
      else
        @app.call(env)
      end
    end
  end
end
