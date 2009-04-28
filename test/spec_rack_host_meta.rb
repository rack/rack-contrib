require 'test/spec'
require 'rack/mock'
require 'rack/contrib/host_meta'
require 'rack/contrib/not_found'

context "Rack::HostMeta" do

  setup do
    app = Rack::Builder.new do
      use Rack::Lint
      use Rack::ContentLength
      use Rack::HostMeta do
        register :uri => '/robots.txt', :rel => 'robots'
        register :uri => '/w3c/p3p.xml', :rel => 'privacy', :type => 'application/p3p.xml'
      end
      run Rack::NotFound.new('test/404.html')
    end
    @response = Rack::MockRequest.new(app).get('/host-meta')
  end

  specify "should respond to /host-meta" do
    @response.status.should.equal 200
  end

  specify "should respond with the correct media type" do
    @response['Content-Type'].should.equal 'application/host-meta'
  end

  specify "should include a Link entry for each item in the config block" do
    @response.body.should.match(/Link:\s*<\/robots.txt>;.*\n/)
    @response.body.should.match(/Link:\s*<\/w3c\/p3p.xml>;.*/)
  end

  specify "should include a rel attribute for each Link entry where specified" do
    @response.body.should.match(/rel="robots"/)
    @response.body.should.match(/rel="privacy"/)
  end

  specify "should include a type attribute for each Link entry where specified" do
    @response.body.should.match(/Link:\s*<\/w3c\/p3p.xml>;.*type.*application\/p3p.xml/)
  end

end
