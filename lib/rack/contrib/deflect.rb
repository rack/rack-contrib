require 'thread'

# TODO: optional stats
# TODO: performance
# TODO: clean up tests

module Rack

  ##
  # Rack middleware for protecting against Denial-of-service attacks
  # http://en.wikipedia.org/wiki/Denial-of-service_attack.
  #
  # This middleware is designed for small deployments, which most likely
  # are not utilizing load balancing from other software or hardware. Deflect
  # current supports the following functionality:
  #
  # * Saturation prevention (small DoS attacks, or request abuse)
  # * Blacklisting of remote addresses
  # * Whitelisting of remote addresses
  # * Logging
  #
  # === Options:
  #
  #   :log                When false logging will be bypassed, otherwise pass an object responding to #puts
  #   :log_format         Alter the logging format
  #   :log_date_format    Alter the logging date format
  #   :request_threshold  Number of requests allowed within the set :interval. Defaults to 100
  #   :interval           Duration in seconds until the request counter is reset. Defaults to 5
  #   :block_duration     Duration in seconds that a remote address will be blocked. Defaults to 900 (15 minutes)
  #   :whitelist          Array of remote addresses which bypass Deflect. NOTE: this does not block others
  #   :blacklist          Array of remote addresses immediately considered malicious
  #
  # === Examples:
  #
  #  use Rack::Deflect, :log => $stdout, :request_threshold => 20, :interval => 2, :block_duration => 60
  #
  # CREDIT: TJ Holowaychuk <tj@vision-media.ca>
  #

  class Deflect

    attr_reader :options

    def initialize app, options = {}
      @mutex = Mutex.new
      @remote_addr_map = {}
      @app, @options = app, {
        :log => false,
        :log_format => 'deflect(%s): %s',
        :log_date_format => '%m/%d/%Y',
        :request_threshold => 100,
        :interval => 5,
        :block_duration => 900,
        :whitelist => [],
        :blacklist => []
      }.merge(options)
    end

    def call env
      return deflect! if deflect? env
      status, headers, body = @app.call env
      [status, headers, body]
    end

    def deflect!
      [403, { 'Content-Type' => 'text/html', 'Content-Length' => '0' }, '']
    end

    def deflect? env
      @remote_addr = env['REMOTE_ADDR']
      return false if options[:whitelist].include? @remote_addr
      return true  if options[:blacklist].include? @remote_addr
      sync { watch }
    end

    def log message
      return unless options[:log]
      options[:log].puts(options[:log_format] % [Time.now.strftime(options[:log_date_format]), message])
    end

    def sync &block
      @mutex.synchronize(&block)
    end

    def map
      @remote_addr_map[@remote_addr] ||= {
        :expires => Time.now + options[:interval],
        :requests => 0
      }
    end

    def watch
      increment_requests
      clear! if watch_expired? and not blocked?
      clear! if blocked? and block_expired?
      block! if watching? and exceeded_request_threshold?
      blocked?
    end

    def block!
      return if blocked?
      log "blocked #{@remote_addr}"
      map[:block_expires] = Time.now + options[:block_duration]
    end

    def blocked?
      map.has_key? :block_expires
    end

    def block_expired?
      map[:block_expires] < Time.now rescue false
    end

    def watching?
      @remote_addr_map.has_key? @remote_addr
    end

    def clear!
      return unless watching?
      log "released #{@remote_addr}" if blocked?
      @remote_addr_map.delete @remote_addr
    end

    def increment_requests
      map[:requests] += 1
    end

    def exceeded_request_threshold?
      map[:requests] > options[:request_threshold]
    end

    def watch_expired?
      map[:expires] <= Time.now
    end

  end
end
