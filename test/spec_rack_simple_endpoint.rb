require 'rack'
require 'rack/contrib/simple_endpoint'

describe "Rack::SimpleEndpoint" do
  before do
    @app = Proc.new { Rack::Response.new {|r| r.write "Downstream app"}.finish }
  end

  it "calls downstream app when no match" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/baz'))
    status.should == 200
    body.body.should == ['Downstream app']
  end

  it "calls downstream app when path matches but method does not" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo' => :get) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo', :method => 'post'))
    status.should == 200
    body.body.should == ['Downstream app']
  end

  it "calls downstream app when path matches but block returns :pass" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') { :pass }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    body.body.should == ['Downstream app']
  end

  it "returns endpoint response when path matches" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    body.body.should == ['bar']
  end

  it "returns endpoint response when path and single method requirement match" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo' => :get) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    body.body.should == ['bar']
  end

  it "returns endpoint response when path and one of multiple method requirements match" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo' => [:get, :post]) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo', :method => 'post'))
    status.should == 200
    body.body.should == ['bar']
  end

  it "returns endpoint response when path matches regex" do
    endpoint = Rack::SimpleEndpoint.new(@app, /foo/) { 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/bar/foo'))
    status.should == 200
    body.body.should == ['bar']
  end

  it "block yields Rack::Request and Rack::Response objects" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') do |req, res|
      req.should.be.instance_of(::Rack::Request)
      res.should.be.instance_of(::Rack::Response)
    end
    endpoint.call(Rack::MockRequest.env_for('/foo'))
  end

  it "block yields MatchData object when Regex path matcher specified" do
    endpoint = Rack::SimpleEndpoint.new(@app, /foo(.+)/) do |req, res, match|
      match.should.be.instance_of(MatchData)
      match[1].should.equal 'bar'
    end
    endpoint.call(Rack::MockRequest.env_for('/foobar'))
  end

  it "block does NOT yield MatchData object when String path matcher specified" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') do |req, res, match|
      match.should.be.nil
    end
    endpoint.call(Rack::MockRequest.env_for('/foo'))
  end

  it "response honors headers set in block" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') {|req, res| res['X-Foo'] = 'bar'; 'baz' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    status.should == 200
    headers['X-Foo'].should == 'bar'
    body.body.should == ['baz']
  end
  
  it "sets Content-Length header" do
    endpoint = Rack::SimpleEndpoint.new(@app, '/foo') {|req, res| 'bar' }
    status, headers, body = endpoint.call(Rack::MockRequest.env_for('/foo'))
    headers['Content-Length'].should == '3'
  end
end
