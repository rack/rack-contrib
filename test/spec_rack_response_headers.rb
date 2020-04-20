require 'minitest/autorun'
require 'rack'
require 'rack/contrib/response_headers'

describe "Rack::ResponseHeaders" do
  def response_header(app, &block)
    Rack::Lint.new(Rack::ResponseHeaders.new(app, &block))
  end

  def env
    Rack::MockRequest.env_for('', {})
  end

  specify "yields a HeaderHash of response headers" do
    orig_headers = {'X-Foo' => 'foo', 'X-Bar' => 'bar'}
    app = Proc.new {[200, orig_headers, []]}
    middleware = response_header(app) do |headers|
      assert_instance_of Rack::Utils::HeaderHash, headers
      _(orig_headers).must_equal headers
    end
    middleware.call(env)
  end

  specify "allows adding headers" do
    app = Proc.new {[200, {'X-Foo' => 'foo'}, []]}
    middleware = response_header(app) do |headers|
      headers['X-Bar'] = 'bar'
    end
    r = middleware.call(env)
    _(r[1]).must_equal('X-Foo' => 'foo', 'X-Bar' => 'bar')
  end

  specify "allows deleting headers" do
    app = Proc.new {[200, {'X-Foo' => 'foo', 'X-Bar' => 'bar'}, []]}
    middleware = response_header(app) do |headers|
      headers.delete('X-Bar')
    end
    r = middleware.call(env)
    _(r[1]).must_equal('X-Foo' => 'foo')
  end

end
