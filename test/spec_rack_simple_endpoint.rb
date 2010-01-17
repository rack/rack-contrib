require 'test/spec'
require 'rack'
require 'rack/contrib/simple_endpoint'

context "Rack::SimpleEndpoint" do
  setup do
    @app = Proc.new { Rack::Response.new {|r| r.write "Downstream app"}.finish }
  end

  specify "calls downstream app when no match" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/baz'))
    status.should == 200
    body.body.should == ['Downstream app']
  end

  specify "calls downstream app when path matches but method does not" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo' => :get) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo', :method => 'post'))
    status.should == 200
    body.body.should == ['Downstream app']
  end

  specify "calls downstream app when path matches but block returns :pass" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') { :pass }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    body.body.should == ['Downstream app']
  end

  specify "returns endpoint response when path matches" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    body.body.should == ['bar']
  end

  specify "returns endpoint response when path and single method requirement match" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo' => :get) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    body.body.should == ['bar']
  end

  specify "returns endpoint response when path and one of multiple method requirements match" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo' => [:get, :post]) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo', :method => 'post'))
    status.should == 200
    body.body.should == ['bar']
  end

  specify "returns endpoint response when path matches regex" do
    endpoint = Rack::SimpleEndpoint.new(@app, /foo/) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/bar/foo'))
    status.should == 200
    body.body.should == ['bar']
  end

  specify "block yields Rack::Request and Rack::Response objects" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') do |req, res|
      assert_instance_of ::Rack::Request, req
      assert_instance_of ::Rack::Response, res
    end
    endpoint.call(Rack::MockRequest.env_for('/foo'))
  end

  specify "block yields MatchData object when Regex path matcher specified" do
    endpoint = Rack::SimpleEndpoint.new(@app, /foo(.+)/) do |req, res, match|
      assert_instance_of MatchData, match
      assert_equal 'bar', match[1]
    end
    endpoint.call(Rack::MockRequest.env_for('/foobar'))
  end

  specify "block does NOT yield MatchData object when String path matcher specified" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') do |req, res, match|
      assert_nil match
    end
    endpoint.call(Rack::MockRequest.env_for('/foo'))
  end

  specify "response honors headers set in block" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') {|req, res| res['X-Foo'] = 'bar'; 'baz' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    headers['X-Foo'].should == 'bar'
    body.body.should == ['baz']
  end
  
  specify "sets Content-Length header" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') {|req, res| 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    headers['Content-Length'].should == '3'
  end
end
