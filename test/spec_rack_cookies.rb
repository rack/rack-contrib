require 'test/spec'
require 'rack/mock'
require 'rack/contrib/cookies'

context "Rack::Cookies" do
  specify "should be able to read received cookies" do
    app = lambda { |env|
      cookies = env['rack.cookies']
      foo, quux = cookies[:foo], cookies['quux']
      [200, {'Content-Type' => 'text/plain'}, ["foo: #{foo}, quux: #{quux}"]]
    }
    app = Rack::Cookies.new(app)

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'foo=bar;quux=h&m')
    response.body.should.equal('foo: bar, quux: h&m')
  end

  specify "should be able to set new cookies" do
    app = lambda { |env|
      cookies = env['rack.cookies']
      cookies[:foo] = 'bar'
      cookies['quux'] = 'h&m'
      [200, {'Content-Type' => 'text/plain'}, []]
    }
    app = Rack::Cookies.new(app)

    response = Rack::MockRequest.new(app).get('/')
    response.headers['Set-Cookie'].should.equal("quux=h%26m; path=/\nfoo=bar; path=/")
  end

  specify "should be able to set cookie with options" do
    app = lambda { |env|
      cookies = env['rack.cookies']
      cookies['foo'] = { :value => 'bar', :path => '/login', :secure => true }
      [200, {'Content-Type' => 'text/plain'}, []]
    }
    app = Rack::Cookies.new(app)

    response = Rack::MockRequest.new(app).get('/')
    response.headers['Set-Cookie'].should.equal('foo=bar; path=/login; secure')
  end

  specify "should be able to delete received cookies" do
    app = lambda { |env|
      cookies = env['rack.cookies']
      cookies.delete(:foo)
      foo, quux = cookies['foo'], cookies[:quux]
      [200, {'Content-Type' => 'text/plain'}, ["foo: #{foo}, quux: #{quux}"]]
    }
    app = Rack::Cookies.new(app)

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'foo=bar;quux=h&m')
    response.body.should.equal('foo: , quux: h&m')
    response.headers['Set-Cookie'].should.equal('foo=; path=/; expires=Thu, 01-Jan-1970 00:00:00 GMT')
  end
end
