# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/builder'
require 'rack/contrib/common_cookies'

describe Rack::CommonCookies do

  before do
    @app = Rack::Lint.new(
      Rack::Builder.new do
        use Rack::CommonCookies
        run lambda {|env| [200, {'Set-Cookie' => env['HTTP_COOKIE']}, []] }
      end
    )
  end

  def request
    Rack::MockRequest.new(@app)
  end

  def make_request(domain, cookies='key=value')
    request.get '/', 'HTTP_COOKIE' => cookies, 'HTTP_HOST' => domain
  end

  specify 'should use .domain.com for cookies from domain.com' do
    response = make_request 'domain.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com'
  end

  specify 'should use .domain.com for cookies from www.domain.com' do
    response = make_request 'www.domain.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com'
  end

  specify 'should use .domain.com for cookies from subdomain.domain.com' do
    response = make_request 'subdomain.domain.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com'
  end

  specify 'should use .domain.com for cookies from 0.subdomain1.subdomain2.domain.com' do
    response = make_request '0.subdomain1.subdomain2.domain.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com'
  end

  specify 'should use .domain.local for cookies from domain.local' do
    response = make_request '0.subdomain1.subdomain2.domain.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com'
  end

  specify 'should use .domain.local for cookies from subdomain.domain.local' do
    response = make_request 'subdomain.domain.local'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.local'
  end

  specify 'should use .domain.com.ua for cookies from domain.com.ua' do
    response = make_request 'domain.com.ua'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com.ua'
  end

  specify 'should use .domain.com.ua for cookies from subdomain.domain.com.ua' do
    response = make_request 'subdomain.domain.com.ua'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.com.ua'
  end

  specify 'should use .domain.co.uk for cookies from domain.co.uk' do
    response = make_request 'domain.co.uk'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.co.uk'
  end

  specify 'should use .domain.co.uk for cookies from subdomain.domain.co.uk' do
    response = make_request 'subdomain.domain.co.uk'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.co.uk'
  end

  specify 'should use .domain.eu.com for cookies from domain.eu.com' do
    response = make_request 'domain.eu.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.eu.com'
  end

  specify 'should use .domain.eu.com for cookies from subdomain.domain.eu.com' do
    response = make_request 'subdomain.domain.eu.com'
    _(response.headers['Set-Cookie']).must_equal 'key=value; domain=.domain.eu.com'
  end

  specify 'should work with multiple cookies' do
    response = make_request 'sub.domain.bz', "key=value\nkey1=value2"
    _(response.headers['Set-Cookie']).must_equal "key=value; domain=.domain.bz\nkey1=value2; domain=.domain.bz"
  end if Rack.release < "3"

  specify 'should not work with multiple cookies' do
    error = _ { make_request 'sub.domain.bz', "key=value\nkey1=value2" }.must_raise(Rack::Lint::LintError)
    _(error.message).must_match(/invalid header value/)
  end if Rack.release > "3"

  specify 'should work with cookies which have explicit domain' do
    response = make_request 'sub.domain.bz', "key=value; domain=domain.bz"
    _(response.headers['Set-Cookie']).must_equal "key=value; domain=.domain.bz"
  end

  specify 'should not touch cookies if domain is localhost' do
    response = make_request 'localhost'
    _(response.headers['Set-Cookie']).must_equal "key=value"
  end

  specify 'should not touch cookies if domain is ip address' do
    response = make_request '127.0.0.1'
    _(response.headers['Set-Cookie']).must_equal "key=value"
  end

  specify 'should use .domain.com for cookies from subdomain.domain.com:3000' do
    response = make_request 'subdomain.domain.com:3000'
    _(response.headers['Set-Cookie']).must_equal "key=value; domain=.domain.com"
  end
end
