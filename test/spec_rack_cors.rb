require 'test/spec'
require 'rack/mock'
require 'rack/contrib/cors'

context "Rack::CORS" do
  setup do
    @app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, env['PATH_INFO']] }
    @no_domains = []
    @allow_all = ['*']
    @specific = ['http://site.com']
    @wildcards = ['http://localhost:*', 'http://*.site.com']
    @all_together_now = @wildcards.concat @specific
    @site_origin = 'http://site.com'
    @site_port = 'http://site.com:8080'
    @site_subdomain = 'http://news.site.com'
    @localhost_plain = 'http://localhost'
    @localhost_rails = 'http://localhost:3000'
    @all_origins = [@site_origin, @site_subdomain, @localhost_rails]
  end

  def mock_origin(origin)
    mock = Rack::MockRequest.env_for('/', { 'HTTP_ORIGIN' => origin })
  end

  def middleware(domain_patterns)
    Rack::CORS.new(@app, domain_patterns)
  end

  specify 'specifying no domains should never set an Access-Control-Allow-Origin' do
    app = middleware(@no_domains)
    @all_origins.each do |origin|
      status, headers, body = app.call(mock_origin(origin))
      headers['Access-Control-Allow-Origin'].should == nil
    end
  end

  specify 'all domains should set Access-Control-Allow-Origin to Origin always' do
    app = middleware(@allow_all)
    @all_origins.each do |origin|
      status, headers, body = app.call(mock_origin(origin))
      headers['Access-Control-Allow-Origin'].should == origin
    end
  end

  specify 'specific (non-globbed) domain patterns should only match one port and subdomain' do
    app = middleware(@specific)
    status, headers, body = app.call(mock_origin(@site_origin))
    headers['Access-Control-Allow-Origin'].should == @site_origin
    status, headers, body = app.call(mock_origin(@site_subdomain))
    headers['Access-Control-Allow-Origin'].should == nil
    status, headers, body = app.call(mock_origin(@site_port))
    headers['Access-Control-Allow-Origin'].should == nil
  end

  specify 'ports and subdomains should be globbable' do
    app = middleware(@wildcards)
    status, headers, body = app.call(mock_origin(@localhost_rails))
    headers['Access-Control-Allow-Origin'].should == @localhost_rails
    status, headers, body = app.call(mock_origin(@site_subdomain))
    headers['Access-Control-Allow-Origin'].should == @site_subdomain
  end

  specify 'all types of patterns should mix well' do
    app = middleware(@all_together_now)
    @all_origins.each do |origin|
      status, headers, body = app.call(mock_origin(origin))
      headers['Access-Control-Allow-Origin'].should == origin
    end
  end
end
