require 'test/spec'
require 'rack/mock'
require 'rack/contrib/jsonp'

context "Rack::JSONP" do

  context "when a callback parameter is provided" do
    specify "should wrap the response body in the Javascript callback" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, test_body] }
      request = Rack::MockRequest.env_for("/", :input => "foo=bar&callback=#{callback}")
      body = Rack::JSONP.new(app).call(request).last
      body.should == "#{callback}(#{test_body})"
    end

    specify "should modify the content length to the correct value" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, test_body] }
      request = Rack::MockRequest.env_for("/", :input => "foo=bar&callback=#{callback}")
      headers = Rack::JSONP.new(app).call(request)[1]
      headers['Content-Length'].should == (test_body.length + callback.length + 2).to_s # 2 parentheses
    end
  end

  specify "should not change anything if no callback param is provided" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, '{"bar":"foo"}'] }
    request = Rack::MockRequest.env_for("/", :input => "foo=bar")
    body = Rack::JSONP.new(app).call(request).last
    body.should == '{"bar":"foo"}'
  end

end
