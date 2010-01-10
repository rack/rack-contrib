require "ipaddr"

module Rack

  ##
  # Rack middleware for limiting access based on IP address, password cookie or a token
  #
  #
  # === Options:
  #
  #   :allow_ipmasks      Array of remote addresses which are allowed to access
  #   :password
  #   :secret_key
  #
  # === Examples:
  #
  #  use Rack::Access, :allow_ipmasks => [ '127.0.0.1',  '192.168.1.0/24' ]
  #
  #

  class Access

    attr_reader :options

    def initialize(app, options = {})
      @app = app
      @options = {
        :allow_ipmasks => ["127.0.0.1"],
        :password => nil,
        :secret_key => nil
      }.merge(options)
      @options[:allow_ipmasks].collect! do |ipmask|
        ipmask.is_a?(IPAddr) ? ipmask : IPAddr.new(ipmask)
      end
    end

    def call(env)
      @original_request = Request.new(env)
      return forbidden! unless ip_authorized?
      status, headers, body = @app.call(env)
      [status, headers, body]
    end

    def forbidden!
      [403, { 'Content-Type' => 'text/html', 'Content-Length' => '0' }, '']
    end

    def ip_authorized?
      return true unless options[:allow_ipmasks]

      options[:allow_ipmasks].any? do |ip_mask|
        ip_mask.include?(IPAddr.new(@original_request.ip))
      end
    end


  end
end
