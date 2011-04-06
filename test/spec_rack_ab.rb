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
    ['rack_ab=a','rack_ab=b'].should.include(response.headers['Set-Cookie'])
  end
  
  specify "should not set a cookie if one is already defined" do
    app = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, '']
    }
    app = Rack::AB.new(app)

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'rack_ab=a')
    response.headers['Set-Cookie'].should == nil
  end
  
end
