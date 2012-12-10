require 'test/spec'
require 'rack/mock'
require 'rack/contrib/jsonp'

context "Rack::JSONP" do

  context "when a callback parameter is provided" do
    specify "should wrap the response body in the Javascript callback if JSON" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [test_body]] }
      request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
      body = Rack::JSONP.new(app).call(request).last
      body.should.equal ["#{callback}(#{test_body})"]
    end
    
    specify "should not wrap the response body in a callback if body is not JSON" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, [test_body]] }
      request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
      body = Rack::JSONP.new(app).call(request).last
      body.should.equal ['{"bar":"foo"}']
    end
    
    specify "should update content length if it was set" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'application/json', 'Content-Length' => test_body.length}, [test_body]] }
      request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")

      headers = Rack::JSONP.new(app).call(request)[1]
      expected_length = test_body.length + callback.length + "()".length
      headers['Content-Length'].should.equal(expected_length.to_s)
    end
    
    specify "should not touch content length if not set" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [test_body]] }
      request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
      headers = Rack::JSONP.new(app).call(request)[1]
      headers['Content-Length'].should.equal nil
    end
    
    specify "should modify the content type to application/javascript" do
      test_body = '{"bar":"foo"}'
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [test_body]] }
      request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
      headers = Rack::JSONP.new(app).call(request)[1]
      headers['Content-Type'].should.equal('application/javascript')
    end

    specify "should not allow literal U+2028 or U+2029" do
      test_body = unless "\u2028" == 'u2028'
        "{\"bar\":\"\u2028 and \u2029\"}"
      else
        "{\"bar\":\"\342\200\250 and \342\200\251\"}"
      end
      callback = 'foo'
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [test_body]] }
      request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
      body = Rack::JSONP.new(app).call(request).last
      unless "\u2028" == 'u2028'
        body.join.should.not.match(/\u2028|\u2029/)
      else
        body.join.should.not.match(/\342\200\250|\342\200\251/)
      end
    end
    
    context "but is empty" do
      specify "should " do
        test_body = '{"bar":"foo"}'
        callback = ''
        app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [test_body]] }
        request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
        body = Rack::JSONP.new(app).call(request).last
        body.should.equal ['{"bar":"foo"}']
      end
    end
    
    context 'but is invalid' do
      context 'with content-type application/json' do
        specify 'should return "Bad Request"' do
          test_body = '{"bar":"foo"}'
          callback = '*'
          content_type = 'application/json'
          app = lambda { |env| [200, {'Content-Type' => content_type}, [test_body]] }
          request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
          body = Rack::JSONP.new(app).call(request).last
          body.should.equal ['Bad Request']
        end

        specify 'should return set the response code to 400' do
          test_body = '{"bar":"foo"}'
          callback = '*'
          content_type = 'application/json'
          app = lambda { |env| [200, {'Content-Type' => content_type}, [test_body]] }
          request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
          response_code = Rack::JSONP.new(app).call(request).first
          response_code.should.equal 400
        end
      end

      context 'with content-type text/plain' do
        specify 'should return "Good Request"' do
          test_body = 'Good Request'
          callback = '*'
          content_type = 'text/plain'
          app = lambda { |env| [200, {'Content-Type' => content_type}, [test_body]] }
          request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
          body = Rack::JSONP.new(app).call(request).last
          body.should.equal ['Good Request']
        end

        specify 'should not change the response code from 200' do
          test_body = '{"bar":"foo"}'
          callback = '*'
          content_type = 'text/plain'
          app = lambda { |env| [200, {'Content-Type' => content_type}, [test_body]] }
          request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
          response_code = Rack::JSONP.new(app).call(request).first
          response_code.should.equal 200
        end
      end
    end

    context "with XSS vulnerability attempts" do
      def request(callback, body = '{"bar":"foo"}')
        app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [body]] }
        request = Rack::MockRequest.env_for("/", :params => "foo=bar&callback=#{callback}")
        Rack::JSONP.new(app).call(request)
      end
      
      def assert_bad_request(response)
        response.should.not.equal nil
        status, headers, body = response
        status.should.equal 400
        body.should.equal ["Bad Request"]
      end
      
      specify "should return bad request for callback with invalid characters" do
        assert_bad_request(request("foo<bar>baz()$"))
      end
      
      specify "should return bad request for callbacks with <script> tags" do
        assert_bad_request(request("foo<script>alert(1)</script>"))
      end
      
      specify "should return bad requests for callbacks with multiple statements" do
        assert_bad_request(request("foo%3balert(1)//")) # would render: "foo;alert(1)//"
      end
      
      specify "should not return a bad request for callbacks with dots in the callback" do
        status, headers, body = request(callback = "foo.bar.baz", test_body = '{"foo":"bar"}')
        status.should.equal 200
        body.should.equal ["#{callback}(#{test_body})"]
      end
    end
    
  end

  specify "should not change anything if no callback param is provided" do
    test_body = ['{"bar":"foo"}']
    app = lambda { |env| [200, {'Content-Type' => 'application/json'}, test_body] }
    request = Rack::MockRequest.env_for("/", :params => "foo=bar")
    body = Rack::JSONP.new(app).call(request).last
    body.should.equal test_body
  end

  specify "should not change anything if it's not a json response" do
    test_body = '<html><body>404 Not Found</body></html>'
    app = lambda { |env| [404, {'Content-Type' => 'text/html'}, [test_body]] }
    request = Rack::MockRequest.env_for("/", :params => "callback=foo", 'HTTP_ACCEPT' => 'application/json')
    body = Rack::JSONP.new(app).call(request).last
    body.should.equal [test_body]
  end
  
  specify "should not change anything if there is no Content-Type header" do
    test_body = '<html><body>404 Not Found</body></html>'
    app = lambda { |env| [404, {}, [test_body]] }
    request = Rack::MockRequest.env_for("/", :params => "callback=foo", 'HTTP_ACCEPT' => 'application/json')
    body = Rack::JSONP.new(app).call(request).last
    body.should.equal [test_body]
  end  

end
