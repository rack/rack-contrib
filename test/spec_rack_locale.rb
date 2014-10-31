require 'rack/mock'

describe "Rack::Locale" do

  before do
    begin
      require 'rack/contrib/locale'
    rescue LoadError
      warn "I18n required for Rack::Locale specs"
    end
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
    response_with_languages(nil).body.should eq('zh')
  end

  specify 'should treat an empty qvalue as 1.0' do
    response_with_languages('en,es;q=0.95').body.should eq('en')
  end

  specify 'should set the Content-Language response header' do
    headers = response_with_languages('de;q=0.7,dk;q=0.9').headers
    headers['Content-Language'].should eq('dk')
  end

  specify 'should pick the language with the highest qvalue' do
    response_with_languages('en;q=0.9,es;q=0.95').body.should eq('es')
  end

  specify 'should retain full language codes' do
    response_with_languages('en-gb,en-us;q=0.95;en').body.should eq('en-gb')
  end

  specify 'should treat a * as "all other languages"' do
    response_with_languages('*,en;q=0.5').body.should eq(I18n.default_locale.to_s )
  end

  specify 'should reset the I18n locale after the response' do
    I18n.locale = 'es'
    response_with_languages('en,de;q=0.8')
    I18n.locale.should eq(:es)
  end

end
