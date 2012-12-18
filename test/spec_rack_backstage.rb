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
    response.body.should eq('Under maintenance.')
    response.status.should eq(503)
  end

  specify "passes on request if page is not present" do
    app = Rack::Builder.new do
      use Rack::Backstage, 'test/Nonsense.html'
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.should eq('Hello, World!')
    response.status.should eq(200)
  end
end
