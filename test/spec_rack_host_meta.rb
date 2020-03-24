require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/host_meta'
require 'rack/contrib/not_found'

describe "Rack::HostMeta" do

  before do
    app = Rack::Builder.new do
      use Rack::Lint
      use Rack::ContentLength
      use Rack::HostMeta do
        link :uri => '/robots.txt', :rel => 'robots'
        link :uri => '/w3c/p3p.xml', :rel => 'privacy', :type => 'application/p3p.xml'
        link :pattern => '{uri};json_schema', :rel => 'describedby', :type => 'application/x-schema+json'
      end
      run Rack::NotFound.new('test/404.html')
    end
    @response = Rack::MockRequest.new(app).get('/host-meta')
  end

  specify "should respond to /host-meta" do
    _(@response.status).must_equal 200
  end

  specify "should respond with the correct media type" do
    _(@response['Content-Type']).must_equal 'application/host-meta'
  end

  specify "should include a Link entry for each Link item in the config block" do
    _(@response.body).must_match(/Link:\s*<\/robots.txt>;.*\n/)
    _(@response.body).must_match(/Link:\s*<\/w3c\/p3p.xml>;.*/)
  end

  specify "should include a Link-Pattern entry for each Link-Pattern item in the config" do
    _(@response.body).must_match(/Link-Pattern:\s*<\{uri\};json_schema>;.*/)
  end

  specify "should include a rel attribute for each Link or Link-Pattern entry where specified" do
    _(@response.body).must_match(/rel="robots"/)
    _(@response.body).must_match(/rel="privacy"/)
    _(@response.body).must_match(/rel="describedby"/)
  end

  specify "should include a type attribute for each Link or Link-Pattern entry where specified" do
    _(@response.body).must_match(/Link:\s*<\/w3c\/p3p.xml>;.*type.*application\/p3p.xml/)
    _(@response.body).must_match(/Link-Pattern:\s*<\{uri\};json_schema>;.*type.*application\/x-schema\+json/)
  end

end
