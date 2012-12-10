module Rack
  # Rack middleware to use common cookies across domain and subdomains.
  class CommonCookies
    DOMAIN_REGEXP = /([^.]*)\.([^.]*|..\...|...\...|..\....)$/
    LOCALHOST_OR_IP_REGEXP = /^([\d.]+|localhost)$/
    PORT = /:\d+$/

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env).tap do |(status, headers, response)|
        @host = env['HTTP_HOST'].sub PORT, ''
        share_cookie headers
      end
    end

    private

    def domain
      @host =~ DOMAIN_REGEXP
      ".#{$1}.#{$2}"
    end

    def share_cookie(headers)
      headers['Set-Cookie'] &&= common_cookie(headers) if @host !~ LOCALHOST_OR_IP_REGEXP
    end

    def cookie(headers)
      cookies = headers['Set-Cookie']
      cookies.is_a?(Array) ? cookies.join("\n") : cookies
    end

    def common_cookie(headers)
      cookie(headers).gsub(/; domain=[^;]*/, '').gsub(/$/, "; domain=#{domain}")
    end
  end
end