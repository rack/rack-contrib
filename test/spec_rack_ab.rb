require 'test/spec'
require 'rack/mock'
require 'rack/contrib/ab'

context "Rack::AB" do
  specify "should return 'a' or 'b' if no cookie is set" do
    app = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, '']
    }
    app = Rack::AB.new(app)

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => '')
    response.headers['Set-Cookie'].should.equal('rack_ab=b; path=/' || 'rack_ab=b; path=/')
  end
end
