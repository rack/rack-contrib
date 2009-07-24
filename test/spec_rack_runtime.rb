require 'test/spec'
require 'rack/mock'
require 'rack/contrib/runtime'

context "Rack::Runtime" do
  specify "sets X-Runtime is none is set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    response = Rack::Runtime.new(app).call({})
    response[1]['X-Runtime'].should =~ /[\d\.]+/
  end

  specify "does not set the X-Runtime if it is already set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain', "X-Runtime" => "foobar"}, "Hello, World!"] }
    response = Rack::Runtime.new(app).call({})
    response[1]['X-Runtime'].should == "foobar"
  end

  specify "should allow a suffix to be set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    response = Rack::Runtime.new(app, "Test").call({})
    response[1]['X-Runtime-Test'].should =~ /[\d\.]+/
  end
end
