require 'rack'
require 'rack/contrib/response_headers'

describe "Rack::ResponseHeaders" do

  it "yields a HeaderHash of response headers" do
    orig_headers = {'X-Foo' => 'foo', 'X-Bar' => 'bar'}
    app = Proc.new {[200, orig_headers, []]}
    middleware = Rack::ResponseHeaders.new(app) do |headers|
      headers.should.be.instance_of(Rack::Utils::HeaderHash)
      orig_headers.should == headers
    end
    middleware.call({})
  end

  it "allows adding headers" do
    app = Proc.new {[200, {'X-Foo' => 'foo'}, []]}
    middleware = Rack::ResponseHeaders.new(app) do |headers|
      headers['X-Bar'] = 'bar'
    end
    r = middleware.call({})
    r[1].should == {'X-Foo' => 'foo', 'X-Bar' => 'bar'}
  end

  it "allows deleting headers" do
    app = Proc.new {[200, {'X-Foo' => 'foo', 'X-Bar' => 'bar'}, []]}
    middleware = Rack::ResponseHeaders.new(app) do |headers|
      headers.delete('X-Bar')
    end
    r = middleware.call({})
    r[1].should == {'X-Foo' => 'foo'}
  end

end