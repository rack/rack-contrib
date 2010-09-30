module Rack
  # Rack middleware to use the same cookies inside domain and all subdomains.
  class CommonCookies
    DOMAIN_REGEXP = /([^.]*)\.([^.]*|..\...|...\...)$/
    LOCALHOST_OR_IP_REGEXP = /^([\d.]+(:\d+)?|localhost)$/

    def initialize(app)
      @app = app
    end

    def domain(env)
      env['HTTP_HOST'] =~ DOMAIN_REGEXP
      ".#{$1}.#{$2}"
    end

    def update_domain(env, headers)
      headers['Set-Cookie'] &&= rewrite cookies if env['HTTP_HOST'] !~ LOCALHOST_OR_IP_REGEXP
    end

    def call(env)
      @app.call(env).tap {|(status, headers, response)| update_domain(env, headers) }
    end

    private

    def cookies
      Array[*headers['Set-Cookie']].join "\n"
    end

    def rewrite(cookies)
      *set_cookies.gsub(/; domain=[^;]*/, '').gsub(/$/, "; domain=#{domain(env)}").split("\n")
    end
  end
end