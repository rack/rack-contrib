require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/accept_format'
require 'rack/mime'

describe "Rack::AcceptFormat" do
  app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }

  specify "should do nothing when a format extension is already provided" do
    request = Rack::MockRequest.env_for("/resource.json")
    body = Rack::AcceptFormat.new(app).call(request).last
    body.must_equal "/resource.json"
  end

  describe "default extention" do
    specify "should allow custom default" do
      request = Rack::MockRequest.env_for("/resource")
      body = Rack::AcceptFormat.new(app, '.xml').call(request).last
      body.must_equal "/resource.xml"
    end

    specify "should default to html" do
      request = Rack::MockRequest.env_for("/resource")
      body = Rack::AcceptFormat.new(app).call(request).last
      body.must_equal "/resource.html"
    end

    specify "should notmalize custom extention" do
      request = Rack::MockRequest.env_for("/resource")

      body = Rack::AcceptFormat.new(app,'xml').call(request).last #no dot prefix
      body.must_equal "/resource.xml"

      body = Rack::AcceptFormat.new(app, :xml).call(request).last
      body.must_equal "/resource.xml"
    end
  end

  describe "there is no format extension" do
    before do
      Rack::Mime::MIME_TYPES.clear
    end

    def mime(ext, type)
      ext = ".#{ext}" unless ext.to_s[0] == ?.
      Rack::Mime::MIME_TYPES[ext.to_s] = type
    end

    specify "should add the default extension if no Accept header" do
      request = Rack::MockRequest.env_for("/resource")
      body = Rack::AcceptFormat.new(app).call(request).last
      body.must_equal "/resource.html"
    end

    specify "should add the default extension if the Accept header is not registered in the Mime::Types" do
      request = Rack::MockRequest.env_for("/resource", 'HTTP_ACCEPT' => 'application/json;q=1.0, text/html;q=0.8, */*;q=0.1')
      body = Rack::AcceptFormat.new(app).call(request).last
      body.must_equal "/resource.html"
    end

    specify "should add the correct extension if the Accept header is registered in the Mime::Types" do
      mime :json, 'application/json'
      request = Rack::MockRequest.env_for("/resource", 'HTTP_ACCEPT' => 'application/json;q=1.0, text/html;q=0.8, */*;q=0.1')
      body = Rack::AcceptFormat.new(app).call(request).last
      body.must_equal "/resource.json"
    end
  end

  specify "shouldn't confuse extention when there are dots in path" do
    request = Rack::MockRequest.env_for("/parent.resource/resource")
    body = Rack::AcceptFormat.new(app, '.html').call(request).last
    body.must_equal "/parent.resource/resource.html"
  end
end
