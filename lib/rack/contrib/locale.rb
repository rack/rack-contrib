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

    # Accept-Language header is covered mainly by RFC 7231
    # https://tools.ietf.org/html/rfc7231
    #
    # Related sections:
    # * https://tools.ietf.org/html/rfc7231#section-5.3.1
    # * https://tools.ietf.org/html/rfc7231#section-5.3.5
    #
    # There is an obsolete RFC 2616 (https://tools.ietf.org/html/rfc2616)
    #
    # Edge cases:
    #
    # * Value can be a comma separated list with optional whitespaces:
    #   Accept-Language: da, en-gb;q=0.8, en;q=0.7
    #
    # * Quality value can contain optional whitespaces as well:
    #   Accept-Language: ru-UA, ru; q=0.8, uk; q=0.6, en-US; q=0.4, en; q=0.2
    #
    def accept_locale(env)
      accept_langs = env["HTTP_ACCEPT_LANGUAGE"]
      return if accept_langs.nil?

      languages_and_qvalues = accept_langs.gsub(/\s+/, '').split(",").map { |l|
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
