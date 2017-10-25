require 'i18n'

module Rack
  class Locale
    def initialize(app)
      @app = app
    end

    def call(env)
      old_locale = I18n.locale

      begin
        locale = accept_locale(env) || I18n.default_locale
        locale = env['rack.locale'] = I18n.locale = locale.to_s
        status, headers, body = @app.call(env)
        headers['Content-Language'] = locale unless headers['Content-Language']
        [status, headers, body]
      ensure
        I18n.locale = old_locale
      end
    end

    private

    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    def accept_locale(env)
      accept_langs = env["HTTP_ACCEPT_LANGUAGE"]
      return if accept_langs.nil?

      languages_and_qvalues = accept_langs.split(",").map { |l|
        l += ';q=1.0' unless l =~ /;q=\d+(?:\.\d+)?$/
        l.split(';q=')
      }

      language_and_qvalue = languages_and_qvalues.sort_by { |(locale, qvalue)|
        qvalue.to_f
      }.reverse.detect { |(locale, qvalue)|
        if I18n.enforce_available_locales
          locale == '*' || I18n.available_locales.include?(locale.to_sym)
        else
          true
        end
      }

      lang = language_and_qvalue && language_and_qvalue.first
      lang == '*' ? nil : lang
    end
  end
end
