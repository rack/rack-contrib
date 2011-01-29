require 'test/spec'
require 'rack/mock'
require 'rack/contrib/bounce_icon'

context "Rack::BounceFavicon" do
  specify "should return 404 and cache headers for favicon requests" do
    app = Rack::Builder.new do
      use Rack::Lint
      run Rack::BounceFavicon.new
    end
    response = Rack::MockRequest.new(app).get('/favicon.ico')
    response.body.should.equal('')
    response.status.should.equal(404)
    response.headers['Content-Length'].should.equal 0
    response.headers['Cache-Control'].should.equal 'max-age=31536000, public'
    response.headers.should.contain 'Expires'
    status.should.equal(404)
  end

  specify "should return 404 and cache headers for favicon requests when using custom expirity" do
    app = Rack::Builder.new do
      use Rack::Lint
      run Rack::BounceFavicon.new :duration => 365 * 24 * 60 * 60 * 5
    end
    response = Rack::MockRequest.new(app).get('/favicon.ico')
    response.body.should.equal('')
    response.status.should.equal(404)
    response.headers['Content-Length'].should.equal 0
    response.headers['Cache-Control'].should.equal 'max-age=157680000, public'
    response.headers.should.contain 'Expires'
    status.should.equal(404)
  end
end
