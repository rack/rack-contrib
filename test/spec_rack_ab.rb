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
    response.headers['Set-Cookie'].should =~ /rack_ab=[a,b]/
  end
  
  specify "should not set a cookie if one is already defined" do
    app = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, '']
    }
    app = Rack::AB.new(app)

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'rack_ab=a')
    response.headers['Set-Cookie'].should == nil
  end
  
  specify "provides a way to set a custom cookie name" do
    app = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, '']
    }
    app = Rack::AB.new(app, :cookie_name => 'new_cookie_name')

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => '')
    response.headers['Set-Cookie'].should =~ /new_cookie_name=[a,b]/
  end
  
  specify "provides a way to set a custom cookie values" do
    app = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, '']
    }
    app = Rack::AB.new(app, :possible_values => [1,2,3])

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => '')
    response.headers['Set-Cookie'].should =~ /rack_ab=[1,2,3]/
  end
  
end
