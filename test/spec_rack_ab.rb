require 'test/spec'
require 'rack/mock'

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
    app = Rack::AB.new(app, :bucket_names => [1,2,3])

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => '')
    response.headers['Set-Cookie'].should =~ /rack_ab=[1,2,3]/
  end
  
  specify "provides a way to set cookie expiration" do
    
    expiration = Time.now+24*60*60
    
    app = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, '']
    }
    app = Rack::AB.new(app, :cookie_params => { :expires => expiration})

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => '')
    
    pattern = "rack_ab=[a,b]; expires=(.*)"
    regexp = Regexp.new(pattern)
    matches = regexp.match response.headers['Set-Cookie']
    
    Time.parse(matches.captures.first).to_s.should.equal expiration.to_s
    
  end
  
  specify "provides a way to split traffic inside app" do
    app = lambda { |env|
      if 'a' == env['rack.ab.bucket_name']
        body = 'content for bucket a'
      elsif 'b' == env['rack.ab.bucket_name']
        body = 'content for bucket b'
      end
      [200, {'Content-Type' => 'text/plain'}, body]
    }
    app = Rack::AB.new(app)

    response = Rack::MockRequest.new(app).get('/', 'HTTP_COOKIE' => 'rack_ab=a')
    
    response.body.should.equal 'content for bucket a'
  end
  
end
