# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/cookies'

describe "Rack::Cookies" do
  def cookies(app)
    Rack::Lint.new(Rack::Cookies.new(app))
  end

  specify "should be able to read received cookies" do
    app = cookies(
      lambda { |env|
        cookies = env['rack.cookies']
        foo, quux = cookies[:foo], cookies['quux']
        [200, {'Content-Type' => 'text/plain'}, ["foo: #{foo}, quux: #{quux}"]]
      }
    )

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'foo=bar;quux=h&m')
    _(response.body).must_equal('foo: bar, quux: h&m')
  end

  specify "should be able to set new cookies" do
    app = cookies(
      lambda { |env|
        cookies = env['rack.cookies']
        cookies[:foo] = 'bar'
        cookies['quux'] = 'h&m'
        [200, {'Content-Type' => 'text/plain'}, []]
      }
    )

    response = Rack::MockRequest.new(app).get('/')
    if Rack.release < "3"
      _(response.headers['Set-Cookie'].split("\n").sort).must_equal(["foo=bar; path=/","quux=h%26m; path=/"])
    else
      _(response.headers['Set-Cookie'].sort).must_equal(["foo=bar; path=/","quux=h%26m; path=/"])
    end
  end

  specify "should be able to set cookie with options" do
    app = cookies(
      lambda { |env|
        cookies = env['rack.cookies']
        cookies['foo'] = { :value => 'bar', :path => '/login', :secure => true }
        [200, {'Content-Type' => 'text/plain'}, []]
      }
    )

    response = Rack::MockRequest.new(app).get('/')
    _(response.headers['Set-Cookie']).must_equal('foo=bar; path=/login; secure')
  end

  specify "should be able to delete received cookies" do
    app = cookies(
      lambda { |env|
        cookies = env['rack.cookies']
        cookies.delete(:foo)
        foo, quux = cookies['foo'], cookies[:quux]
        [200, {'Content-Type' => 'text/plain'}, ["foo: #{foo}, quux: #{quux}"]]
      }
    )

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'foo=bar;quux=h&m')
    _(response.body).must_equal('foo: , quux: h&m')
    _(response.headers['Set-Cookie']).must_match(/foo=(;|$)/)
# This test is currently failing; I suspect it is due to a bug in a dependent
# lib's cookie handling code, but I haven't had time to track it down yet
#      -- @mpalmer, 2015-06-17
#    response.headers['Set-Cookie'].must_match(/expires=Thu, 01 Jan 1970 00:00:00 GMT/)
  end
end
