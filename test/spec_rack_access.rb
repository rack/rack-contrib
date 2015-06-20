require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/access'

describe "Rack::Access" do

  before do
    @app = lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['hello']] }
    @mock_addr_1 = '111.111.111.111'
    @mock_addr_2 = '192.168.1.222'
    @mock_addr_localhost = '127.0.0.1'
    @mock_addr_range = '192.168.1.0/24'
  end

  def mock_env(remote_addr, path = '/')
    Rack::MockRequest.env_for(path, { 'REMOTE_ADDR' => remote_addr })
  end

  def middleware(options = {})
    Rack::Access.new(@app, options)
  end

  specify "default configuration should deny non-local requests" do
    app = middleware
    status, headers, body = app.call(mock_env(@mock_addr_1))
    status.must_equal 403
    body.must_equal []
  end

  specify "default configuration should allow requests from 127.0.0.1" do
    app = middleware
    status, headers, body = app.call(mock_env(@mock_addr_localhost))
    status.must_equal 200
    body.must_equal ['hello']
  end

  specify "should allow remote addresses in allow_ipmasking" do
    app = middleware('/' => [@mock_addr_1])
    status, headers, body = app.call(mock_env(@mock_addr_1))
    status.must_equal 200
    body.must_equal ['hello']
  end

  specify "should deny remote addresses not in allow_ipmasks" do
    app = middleware('/' => [@mock_addr_1])
    status, headers, body = app.call(mock_env(@mock_addr_2))
    status.must_equal 403
    body.must_equal []
  end

  specify "should allow remote addresses in allow_ipmasks range" do
    app = middleware('/' => [@mock_addr_range])
    status, headers, body = app.call(mock_env(@mock_addr_2))
    status.must_equal 200
    body.must_equal ['hello']
  end

  specify "should deny remote addresses not in allow_ipmasks range" do
    app = middleware('/' => [@mock_addr_range])
    status, headers, body = app.call(mock_env(@mock_addr_1))
    status.must_equal 403
    body.must_equal []
  end

  specify "should allow remote addresses in one of allow_ipmasking" do
    app = middleware('/' => [@mock_addr_range, @mock_addr_localhost])

    status, headers, body = app.call(mock_env(@mock_addr_2))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_localhost))
    status.must_equal 200
    body.must_equal ['hello']
  end

  specify "should deny remote addresses not in one of allow_ipmasks" do
    app = middleware('/' => [@mock_addr_range, @mock_addr_localhost])
    status, headers, body = app.call(mock_env(@mock_addr_1))
    status.must_equal 403
    body.must_equal []
  end

  specify "handles paths correctly" do
    app = middleware({
      'http://foo.org/bar' => [@mock_addr_localhost],
      '/foo' => [@mock_addr_localhost],
      '/foo/bar' => [@mock_addr_range, @mock_addr_localhost]
    })

    status, headers, body = app.call(mock_env(@mock_addr_1, "/"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/qux"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/foo"))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/foo"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/foo/"))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/foo/"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/foo/bar"))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/foo/bar"))
    status.must_equal 200
    body.must_equal ['hello']
    status, headers, body = app.call(mock_env(@mock_addr_2, "/foo/bar"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/foo/bar/"))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/foo/bar/"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/foo///bar//quux"))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/foo///bar//quux"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/foo/quux"))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/foo/quux"))
    status.must_equal 200
    body.must_equal ['hello']

    status, headers, body = app.call(mock_env(@mock_addr_1, "/bar"))
    status.must_equal 200
    body.must_equal ['hello']
    status, headers, body = app.call(mock_env(@mock_addr_1, "/bar").merge('HTTP_HOST' => 'foo.org'))
    status.must_equal 403
    body.must_equal []
    status, headers, body = app.call(mock_env(@mock_addr_localhost, "/bar").merge('HTTP_HOST' => 'foo.org'))
    status.must_equal 200
    body.must_equal ['hello']
  end
end
