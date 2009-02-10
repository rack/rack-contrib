require 'test/spec'
require 'rack/mock'
require 'rack/contrib/accept_format'
require 'rack/mime'

context "Rack::AcceptFormat" do
  specify "should do nothing when a format extension is already provided" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }
    request = Rack::MockRequest.env_for("/resource.json")
    body = Rack::AcceptFormat.new(app).call(request).last
    body.should == "/resource.json"
  end

  context "there is no format extension" do
    Rack::Mime::MIME_TYPES.clear
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }
    def mime(ext, type)
      ext = ".#{ext}" unless ext.to_s[0] == ?.
      Rack::Mime::MIME_TYPES[ext.to_s] = type
    end

    specify "should add the default extension if no Accept header" do
      request = Rack::MockRequest.env_for("/resource")
      body = Rack::AcceptFormat.new(app).call(request).last
      body.should == "/resource#{Rack::AcceptFormat::DEFAULT_EXTENSION}"
    end

    specify "should add the default extension if the Accept header is not registered in the Mime::Types" do
      request = Rack::MockRequest.env_for("/resource", 'HTTP_ACCEPT' => 'application/json;q=1.0, text/html;q=0.8, */*;q=0.1')
      body = Rack::AcceptFormat.new(app).call(request).last
      body.should == "/resource#{Rack::AcceptFormat::DEFAULT_EXTENSION}"
    end

    specify "should add the correct extension if the Accept header is registered in the Mime::Types" do
      mime :json, 'application/json'
      request = Rack::MockRequest.env_for("/resource", 'HTTP_ACCEPT' => 'application/json;q=1.0, text/html;q=0.8, */*;q=0.1')
      body = Rack::AcceptFormat.new(app).call(request).last
      body.should == "/resource.json"
    end
  end
end
