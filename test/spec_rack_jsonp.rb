require 'rack/mock'
require 'rack/contrib/jsonp'

context "Rack::JSONP" do
  
  specify "should wrap the response body in the Javascript callback when provided" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, '{"bar":"foo"}'] }
    request = Rack::MockRequest.env_for("/", :input => "foo=bar&callback=foo")
    body = Rack::JSONP.new(app).call(request).last
    body.should == 'foo({"bar":"foo"})'
  end
  
  specify "should not change anything if no :callback param is provided" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, '{"bar":"foo"}'] }
    request = Rack::MockRequest.env_for("/", :input => "foo=bar")
    body = Rack::JSONP.new(app).call(request).last
    body.should == '{"bar":"foo"}'
  end
  
end
