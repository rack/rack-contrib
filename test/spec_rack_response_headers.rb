# frozen_string_literal: true

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

  specify "yields a HeaderHash (rack 2) or Headers (rack 3) of response headers" do
    orig_headers = {'X-Foo' => 'foo', 'X-Bar' => 'bar'}
    app = Proc.new {[200, orig_headers, []]}
    headers_klass = Rack.release < "3" ? Rack::Utils::HeaderHash : Rack::Headers
    middleware = response_header(app) do |headers|
      assert_instance_of headers_klass, headers
      if Rack.release < "3"
        _(orig_headers).must_equal headers
      else
        _(orig_headers).must_equal({'X-Foo' => 'foo', 'X-Bar' => 'bar'})
      end
    end
    middleware.call(env)
  end

  specify "allows adding headers" do
    app = Proc.new {[200, {'X-Foo' => 'foo'}, []]}
    middleware = response_header(app) do |headers|
      headers['X-Bar'] = 'bar'
    end
    r = middleware.call(env)
    if Rack.release < "3"
      _(r[1]).must_equal('X-Foo' => 'foo', 'X-Bar' => 'bar')
    else
      _(r[1]).must_equal('x-foo' => 'foo', 'x-bar' => 'bar')
    end
  end

  specify "allows deleting headers" do
    app = Proc.new {[200, {'X-Foo' => 'foo', 'X-Bar' => 'bar'}, []]}
    middleware = response_header(app) do |headers|
      headers.delete('X-Bar')
    end
    r = middleware.call(env)
    if Rack.release < "3"
      _(r[1]).must_equal('X-Foo' => 'foo')
    else
      _(r[1]).must_equal('x-foo' => 'foo')
    end
  end

end
