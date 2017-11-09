require 'minitest/autorun'
require 'rack/builder'
require 'rack/mock'
require 'rack/contrib/backstage'

describe "Rack::Backstage" do
  specify "shows maintenances page if present" do
    app = Rack::Builder.new do
      use Rack::Backstage, 'test/Maintenance.html'
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal('Under maintenance.')
    response.status.must_equal(503)
  end

  specify "passes on request if page is not present" do
    app = Rack::Builder.new do
      use Rack::Backstage, 'test/Nonsense.html'
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal('Hello, World!')
    response.status.must_equal(200)
  end
end
