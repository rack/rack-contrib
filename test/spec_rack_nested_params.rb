require 'test/spec'
require 'rack/mock'
require 'rack/contrib/nested_params'
require 'rack/methodoverride'

context Rack::NestedParams do

  App = lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env)] }

  def env_for_post_with_headers(path, headers, body)
    Rack::MockRequest.env_for(path, {:method => "POST", :input => body}.merge(headers))
  end

  def form_post(params, content_type = 'application/x-www-form-urlencoded')
    params = Rack::Utils.build_query(params) if Hash === params
    env_for_post_with_headers('/', {'CONTENT_TYPE' => content_type}, params)
  end

  def middleware
    Rack::NestedParams.new(App)
  end

  specify "should handle requests with POST body Content-Type of application/x-www-form-urlencoded" do
    req = middleware.call(form_post({'foo[bar][baz]' => 'nested'})).last
    req.POST.should.equal({"foo" => { "bar" => { "baz" => "nested" }}})
  end

  specify "should not parse requests with other Content-Type" do
    req = middleware.call(form_post({'foo[bar][baz]' => 'nested'}, 'text/plain')).last
    req.POST.should.equal({})
  end

  specify "should work even after another middleware already parsed the request" do
    app = Rack::MethodOverride.new(middleware)
    req = app.call(form_post({'_method' => 'put', 'foo[bar]' => 'nested'})).last
    req.POST.should.equal({'_method' => 'put', "foo" => { "bar" => "nested" }})
    req.put?.should.equal true
  end

  specify "should make first boolean have precedence even after request already parsed" do
    app = Rack::MethodOverride.new(middleware)
    req = app.call(form_post("foo=1&foo=0")).last
    req.POST.should.equal({"foo" => '1'})
  end

end
