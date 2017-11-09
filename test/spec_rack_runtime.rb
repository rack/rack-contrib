require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/runtime'

describe "Rack::Runtime" do
  specify "sets X-Runtime is none is set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    response = Rack::Runtime.new(app).call({})
    response[1]['X-Runtime'].must_match /[\d\.]+/
  end

  specify "does not set the X-Runtime if it is already set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain', "X-Runtime" => "foobar"}, "Hello, World!"] }
    response = Rack::Runtime.new(app).call({})
    response[1]['X-Runtime'].must_equal "foobar"
  end

  specify "should allow a suffix to be set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    response = Rack::Runtime.new(app, "Test").call({})
    response[1]['X-Runtime-Test'].must_match /[\d\.]+/
  end

  specify "should allow multiple timers to be set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    runtime1 = Rack::Runtime.new(app, "App")
    runtime2 = Rack::Runtime.new(runtime1, "All")
    response = runtime2.call({})

    response[1]['X-Runtime-App'].must_match /[\d\.]+/
    response[1]['X-Runtime-All'].must_match /[\d\.]+/

    (Float(response[1]['X-Runtime-All']) > Float(response[1]['X-Runtime-App'])).must_equal(true)
  end
end
