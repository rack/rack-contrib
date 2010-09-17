require 'net/smtp'
require 'tmail'
require 'erb'

module Rack
  # Catches all exceptions raised from the app it wraps and
  # sends a useful email with the exception, stacktrace, and
  # contents of the environment.

  class MailExceptions
    attr_reader :config

    def initialize(app)
      @app = app
      @config = {
        :to      => nil,
        :from    => ENV['USER'] || 'rack',
        :subject => '[exception] %s',
        :smtp    => {
          :server         => 'localhost',
          :domain         => 'localhost',
          :port           => 25,
          :authentication => :login,
          :user_name      => nil,
          :password       => nil
        }
      }
      @template = ERB.new(TEMPLATE)
      yield self if block_given?
    end

    def call(env)
      status, headers, body =
        begin
          @app.call(env)
        rescue => boom
          # TODO don't allow exceptions from send_notification to
          # propogate
          send_notification boom, env
          raise
        end
      send_notification env['mail.exception'], env if env['mail.exception']
      [status, headers, body]
    end

    %w[to from subject].each do |meth|
      define_method(meth) { |value| @config[meth.to_sym] = value }
    end

    def smtp(settings={})
      @config[:smtp].merge! settings
    end

  private
    def generate_mail(exception, env)
      mail = TMail::Mail.new
      mail.to = Array(config[:to])
      mail.from = config[:from]
      mail.subject = config[:subject] % [exception.to_s]
      mail.date = Time.now
      mail.set_content_type 'text/plain'
      mail.charset = 'UTF-8'
      mail.body = @template.result(binding)
      mail
    end

    def send_notification(exception, env)
      mail = generate_mail(exception, env)
      smtp = config[:smtp]
      env['mail.sent'] = true
      return if smtp[:server] == 'example.com'

      server = service.new(smtp[:server], smtp[:port])

      if smtp[:enable_starttls_auto] == :auto
        server.enable_starttls_auto 
      elsif smtp[:enable_starttls_auto]
        server.enable_starttls 
      end

      server.start smtp[:domain], smtp[:user_name], smtp[:password], smtp[:authentication]

      mail.to.each do |recipient|
        server.send_message mail.to_s, mail.from, recipient
      end
    end

    def service
      Net::SMTP
    end

    def extract_body(env)
      if io = env['rack.input']
        io.rewind if io.respond_to?(:rewind)
        io.read
      end
    end

    TEMPLATE = (<<-'EMAIL').gsub(/^ {4}/, '')
    A <%= exception.class.to_s %> occured: <%= exception.to_s %>
    <% if body = extract_body(env) %>

    ===================================================================
    Request Body:
    ===================================================================

    <%= body.gsub(/^/, '  ') %>
    <% end %>

    ===================================================================
    Rack Environment:
    ===================================================================

      PID:                     <%= $$ %>
      PWD:                     <%= Dir.getwd %>

      <%= env.to_a.
        sort{|a,b| a.first <=> b.first}.
        map{ |k,v| "%-25s%p" % [k+':', v] }.
        join("\n  ") %>

    <% if exception.respond_to?(:backtrace) %>
    ===================================================================
    Backtrace:
    ===================================================================

      <%= exception.backtrace.join("\n  ") %>
    <% end %>
    EMAIL

  end
end
