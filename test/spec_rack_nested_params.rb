# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/nested_params'
require 'rack/method_override'

describe Rack::NestedParams do

  request_object = nil
  App = lambda { |env| request_object = Rack::Request.new(env); [200, {'content-type' => 'text/plain'}, []] }

  def env_for_post_with_headers(path, headers, body)
    Rack::MockRequest.env_for(path, {:method => "POST", :input => body}.merge(headers))
  end

  def form_post(params, content_type = 'application/x-www-form-urlencoded')
    params = Rack::Utils.build_query(params) if Hash === params
    env_for_post_with_headers('/', {'CONTENT_TYPE' => content_type}, params)
  end

  def middleware
    # Rack::Lint can't be used because it does not rewind the body
    Rack::NestedParams.new(App)
  end

  specify "should handle requests with POST body content-type of application/x-www-form-urlencoded" do
    req = middleware.call(form_post({'foo[bar][baz]' => 'nested'})).last
    _(request_object.POST).must_equal({"foo" => { "bar" => { "baz" => "nested" }}})
  end

  specify "should not parse requests with other content-type" do
    req = middleware.call(form_post({'foo[bar][baz]' => 'nested'}, 'text/plain')).last
    _(request_object.POST).must_equal({})
  end

  specify "should work even after another middleware already parsed the request" do
    app = Rack::MethodOverride.new(middleware)
    req = app.call(form_post({'_method' => 'put', 'foo[bar]' => 'nested'})).last
    _(request_object.POST).must_equal({'_method' => 'put', "foo" => { "bar" => "nested" }})
    _(request_object.put?).must_equal true
  end

  specify "should make last boolean have precedence even after request already parsed" do
    app = Rack::MethodOverride.new(middleware)
    req = app.call(form_post("foo=1&foo=0")).last
    _(request_object.POST).must_equal({"foo" => "0"})
  end

end
