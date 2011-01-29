require 'time'
module Rack

  # The Rack::BounceIcon middleware intercepts requests for /favicon.ico
  # and returns a 404 with a cache expirity (default 1 year).
  #
  # This middle accepts a hash with possible values as follows:
  #
  # :duration  -  This is the value in seconds that the cache headers will
  #               be set for. The default is 31536000 (1 year).
  #
  # Usage Examples:
  #
  # Basic usage
  #
  #     use Rack::BounceIcon
  #
  # Manually specify a cache duration of 5 years.
  #
  #     use Rack::BounceIcon, :duration => 365 * 24 * 60 * 60 * 5
  #
  class BounceFavicon
    def initialize(app, options={})
      @app = app
      @expire_duration = options[:duration] || 31536000 # =1year
    end

    def call(env)
      if env["PATH_INFO"] == "/favicon.ico"
        headers = {
            "Content-Type" => "text/html",
            "Content-Length" => "0",
            "Cache-Control" => "max-age=#{@expire_duration}, public",
            "Expires" => (Time.now + @expire_duration).httpdate }
        [404, headers, []]
      else
        @app.call(env)
      end
    end
  end
end
