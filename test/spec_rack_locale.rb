require 'minitest/autorun'
require 'minitest/hooks'
require 'rack/mock'

begin
  require './lib/rack/contrib/locale'

  describe "Rack::Locale" do
    include Minitest::Hooks

    before(:all) do
      # Set the locales that will be used at various points in the tests
      I18n.config.available_locales = [I18n.default_locale, :dk, :'en-gb', :es, :zh]
    end

    def app
      @app ||= Rack::Builder.new do
        use Rack::Locale
        run lambda { |env| [ 200, {}, [ I18n.locale.to_s ] ] }
      end
    end

    def response_with_languages(accept_languages)
      Rack::MockRequest.new(app).get('/', { 'HTTP_ACCEPT_LANGUAGE' => accept_languages } )
    end

    specify 'should use I18n.default_locale if no languages are requested' do
      I18n.default_locale = :zh
      response_with_languages(nil).body.must_equal('zh')
    end

    specify 'should treat an empty qvalue as 1.0' do
      response_with_languages('en,es;q=0.95').body.must_equal('en')
    end

    specify 'should set the Content-Language response header' do
      headers = response_with_languages('de;q=0.7,dk;q=0.9').headers
      headers['Content-Language'].must_equal('dk')
    end

    specify 'should pick the language with the highest qvalue' do
      response_with_languages('en;q=0.9,es;q=0.95').body.must_equal('es')
    end

    specify 'should retain full language codes' do
      response_with_languages('en-gb,en-us;q=0.95;en').body.must_equal('en-gb')
    end

    specify 'should treat a * as "all other languages"' do
      response_with_languages('*,en;q=0.5').body.must_equal( I18n.default_locale.to_s )
    end

    specify 'should reset the I18n locale after the response' do
      I18n.locale = :es
      response_with_languages('en,de;q=0.8')
      I18n.locale.must_equal(:es)
    end
  end
rescue LoadError
  STDERR.puts "WARN: Skipping Rack::Locale tests (i18n not installed)"
end
