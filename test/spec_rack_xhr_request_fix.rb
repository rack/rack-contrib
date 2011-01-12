require 'rubygems'
require 'test/spec'
require 'rack/mock'
require 'rack/contrib/xhr_request_fix'
require 'rack/contrib/runtime'

context "Rack::XhrRequestFix" do
  specify "sets XHR header when url param is set" do
    env = { 'QUERY_STRING' => '_xhr' }
    app = lambda do |env|
      env['HTTP_X_REQUESTED_WITH'].should.equal 'XMLHttpRequest'
      [200, {}, ""]
    end
    Rack::XhrRequestFix.new(app).call(env)
  end

  specify "modify location query string on redirect 301 when xhr request" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [301, {"Location" => 'http://test.local'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app).call(env)
    headers['Location'].should =~ /_xhr/
  end

  specify "modify location query string on redirect 302 when xhr request" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [302, {"Location" => 'http://test.local?lala=dude'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app).call(env)
    headers['Location'].should =~ /_xhr/
    headers['Location'].should =~ /lala=dude/
  end

  specify "modify location query string on redirect 303 when xhr request" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [303, {"Location" => 'http://test.local'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app).call(env)
    headers['Location'].should =~ /_xhr/
  end

  specify "modify location query string on redirect 307 when xhr request" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [307, {"Location" => 'http://test.local'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app).call(env)
    headers['Location'].should =~ /_xhr/
  end

  specify "should not crash when redirecting with missing location header" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [301, {}, ""]
    end
    lambda { Rack::XhrRequestFix.new(app).call(env) }.should.not.raise
  end

  specify "not modify location query string on redirect 307 when not xhr request" do
    env = { }
    app = lambda do |env|
      [301, {"Location" => 'http://test.local'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app).call(env)
    headers['Location'].should.not =~ /_xhr/
  end

  specify "not modify location query string on status 200 when xhr request" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [200, {"Location" => 'http://test.local'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app).call(env)
    headers['Location'].should.not =~ /_xhr/
  end

  specify "modify location query string with alternative token" do
    env = { 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest' }
    app = lambda do |env|
      [301, {"Location" => 'http://test.local'}, ""]
    end
    status, headers, body = Rack::XhrRequestFix.new(app, 'alt_token').call(env)
    headers['Location'].should =~ /alt_token/
  end

  specify "sets XHR header with alternative token" do
    env = { 'QUERY_STRING' => 'alt_token' }
    app = lambda do |env|
      env['HTTP_X_REQUESTED_WITH'].should.equal 'XMLHttpRequest'
      [200, {}, ""]
    end
    Rack::XhrRequestFix.new(app, 'alt_token').call(env)
  end

end
