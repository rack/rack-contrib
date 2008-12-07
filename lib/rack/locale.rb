require 'i18n'

module Rack
  class Locale
    def initialize(app)
      @app = app
    end

    def call(env)
      old_locale = I18n.locale
      locale = nil

      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
      if lang = env["HTTP_ACCEPT_LANGUAGE"]
        lang = lang.split(",").map { |l|
          l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
          l.split(';q=')
        }.first
        locale = lang.first.split("-").first
      else
        locale = I18n.default_locale
      end

      locale = env['rack.locale'] = I18n.locale = locale.to_s
      status, headers, body = @app.call(env)
      headers['Content-Language'] = locale
      I18n.locale = old_locale
      [status, headers, body]
    end
  end
end
