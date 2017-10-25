require 'minitest/autorun'
require 'rack/mock'

begin
  require 'rack/contrib/post_body_content_type_parser'

  describe "Rack::PostBodyContentTypeParser" do

    specify "should parse 'application/json' requests" do
      params = params_for_request '{"key":"value"}', "application/json"
      params['key'].must_equal "value"
    end

    specify "should parse 'application/json; charset=utf-8' requests" do
      params = params_for_request '{"key":"value"}', "application/json; charset=utf-8"
      params['key'].must_equal "value"
    end

    specify "should parse 'application/json' requests with empty body" do
      params = params_for_request "", "application/json"
      params.must_equal({})
    end

    specify "shouldn't affect form-urlencoded requests" do
      params = params_for_request("key=value", "application/x-www-form-urlencoded")
      params['key'].must_equal "value"
    end

    specify "should not create additions" do
      before = Symbol.all_symbols
      params_for_request %{{"json_class":"this_should_not_be_added"}}, "application/json" rescue nil
      result = Symbol.all_symbols - before
      result.must_be_empty
    end

    describe "contradiction between body and type" do
      def assert_failed_to_parse_as_json(response)
        response.wont_be_nil
        status, headers, body = response
        status.must_equal 400
        body.must_equal ["failed to parse body as JSON"]
      end

      specify "should return bad request with invalid JSON" do
        test_body = '"bar":"foo"}'
        env = Rack::MockRequest.env_for "/", {:method => "POST", :input => test_body, "CONTENT_TYPE" => 'application/json'}
        app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env).POST] }
        response = Rack::PostBodyContentTypeParser.new(app).call(env)

        assert_failed_to_parse_as_json(response)
      end
    end
  end

  def params_for_request(body, content_type)
    env = Rack::MockRequest.env_for "/", {:method => "POST", :input => body, "CONTENT_TYPE" => content_type}
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env).POST] }
    Rack::PostBodyContentTypeParser.new(app).call(env).last
  end

rescue LoadError => e
  # Missing dependency JSON, skipping tests.
  STDERR.puts "WARN: Skipping Rack::PostBodyContentTypeParser tests (json not installed)"
end
