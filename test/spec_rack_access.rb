# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/access'

describe "Rack::Access" do

  before do
    @app = lambda { |env| [200, { 'content-type' => 'text/plain' }, ['hello']] }
    @mock_addr_1 = '111.111.111.111'
    @mock_addr_2 = '192.168.1.222'
    @mock_addr_localhost = '127.0.0.1'
    @mock_addr_range = '192.168.1.0/24'
  end

  def mock_env(remote_addr, path = '/')
    Rack::MockRequest.env_for(path, { 'REMOTE_ADDR' => remote_addr })
  end

  def access(app, options = {})
    Rack::Lint.new(Rack::Access.new(app, options))
  end

  specify "default configuration should deny non-local requests" do
    req = Rack::MockRequest.new(access(@app))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_1)

    _(res.status).must_equal 403
    _(res.body).must_equal ''
  end

  specify "default configuration should allow requests from 127.0.0.1" do
    req = Rack::MockRequest.new(access(@app))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_localhost)

    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
  end

  specify "should allow remote addresses in allow_ipmasking" do
    req = Rack::MockRequest.new(access(@app, '/' => [@mock_addr_1]))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_1)

    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
  end

  specify "should deny remote addresses not in allow_ipmasks" do
    req = Rack::MockRequest.new(access(@app, '/' => [@mock_addr_1]))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_2)

    _(res.status).must_equal 403
    _(res.body).must_equal ''
  end

  specify "should allow remote addresses in allow_ipmasks range" do
    req = Rack::MockRequest.new(access(@app, '/' => [@mock_addr_range]))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_2)

    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
  end

  specify "should deny remote addresses not in allow_ipmasks range" do
    req = Rack::MockRequest.new(access(@app, '/' => [@mock_addr_range]))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_1)

    _(res.status).must_equal 403
    _(res.body).must_equal ''
  end

  specify "should allow remote addresses in one of allow_ipmasking" do
    req = Rack::MockRequest.new(access(@app, '/' => [@mock_addr_range, @mock_addr_localhost]))

    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_2)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
  end

  specify "should deny remote addresses not in one of allow_ipmasks" do
    req = Rack::MockRequest.new(access(@app, '/' => [@mock_addr_range, @mock_addr_localhost]))
    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_1)

    _(res.status).must_equal 403
    _(res.body).must_equal ''
  end

  specify "handles paths correctly" do
    req = Rack::MockRequest.new(
      access(
        @app,
        'http://foo.org/bar' => [@mock_addr_localhost],
        '/foo'               => [@mock_addr_localhost],
        '/foo/bar'           => [@mock_addr_range, @mock_addr_localhost]
      )
    )

    res = req.get('/', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/qux', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/foo', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/foo', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/foo/', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/foo/', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/foo/bar', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/foo/bar', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
    res = req.get('/foo/bar', 'REMOTE_ADDR' => @mock_addr_2)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/foo/bar/', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/foo/bar/', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/foo///bar//quux', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/foo///bar//quux', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/foo/quux', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/foo/quux', 'REMOTE_ADDR' => @mock_addr_localhost)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'

    res = req.get('/bar', 'REMOTE_ADDR' => @mock_addr_1)
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
    res = req.get('/bar', 'REMOTE_ADDR' => @mock_addr_1, 'HTTP_HOST' => 'foo.org')
    _(res.status).must_equal 403
    _(res.body).must_equal ''
    res = req.get('/bar', 'REMOTE_ADDR' => @mock_addr_localhost, 'HTTP_HOST' => 'foo.org')
    _(res.status).must_equal 200
    _(res.body).must_equal 'hello'
  end
end
