# frozen_string_literal: true

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
      status, headers, body = @app.call(env)
      headers = Headers[headers]

      host = env['HTTP_HOST'].sub PORT, ''
      share_cookie(headers, host)

      [status, headers, body]
    end

    private

    def domain(host)
      host =~ DOMAIN_REGEXP
      ".#{$1}.#{$2}"
    end

    def share_cookie(headers, host)
      return if host =~ LOCALHOST_OR_IP_REGEXP

      cookies = headers['set-cookie']
      return unless cookies

      headers['set-cookie'] = if cookies.is_a?(Array)
        cookies.map { |cookie| common_cookie(cookie, host) }
      else
        common_cookie(cookies, host)
      end
    end

    def common_cookie(cookie, host)
      cookie.gsub(/; domain=[^;]*/, '').gsub(/$/, "; domain=#{domain(host)}")
    end
  end
end
