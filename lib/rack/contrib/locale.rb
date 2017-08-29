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
      }.sort_by { |(locale, qvalue)|
        qvalue.to_f
      }.reverse

      lang = if I18n.enforce_available_locales
        (languages_and_qvalues.detect { |(locale, qvalue)|
          locale == '*' || I18n.available_locales.include?(locale.to_sym)
        } ||
        languages_and_qvalues.collect { |(locale, qvalue)|
          [ locale.split('-').first, qvalue ]
        }.detect { |(locale, qvalue)|
          I18n.available_locales.include?(locale.to_sym)
        }).first
      else
        languages_and_qvalues.first.first
      end

      lang == '*' ? nil : lang
    end
  end
end
