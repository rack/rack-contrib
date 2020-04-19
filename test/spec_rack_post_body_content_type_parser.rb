require 'minitest/autorun'
require 'rack/mock'

begin
  require 'rack/contrib/post_body_content_type_parser'

  describe "Rack::PostBodyContentTypeParser" do

    specify "should parse 'application/json' requests" do
      params = params_for_request '{"key":"value"}', "application/json"
      _(params['key']).must_equal "value"
    end

    specify "should parse 'application/json; charset=utf-8' requests" do
      params = params_for_request '{"key":"value"}', "application/json; charset=utf-8"
      _(params['key']).must_equal "value"
    end

    specify "should parse 'application/json' requests with empty body" do
      params = params_for_request "", "application/json"
      _(params).must_equal({})
    end

    specify "shouldn't affect form-urlencoded requests" do
      params = params_for_request("key=value", "application/x-www-form-urlencoded")
      _(params['key']).must_equal "value"
    end

    specify "should not create additions" do
      before = Symbol.all_symbols
      params_for_request %{{"json_class":"this_should_not_be_added"}}, "application/json" rescue nil
      result = Symbol.all_symbols - before
      _(result).must_be_empty
    end

    specify "should apply given block to body" do
      params = params_for_request '{"key":"value"}', "application/json" do |body|
        { 'payload' => JSON.parse(body) }
      end
      _(params['payload']).wont_be_nil
      _(params['payload']['key']).must_equal "value"
    end

    describe "contradiction between body and type" do
      def assert_failed_to_parse_as_json(response)
        _(response).wont_be_nil
        status, headers, body = response
        _(status).must_equal 400
        _(body.to_enum.to_a).must_equal ["failed to parse body as JSON"]
      end

      specify "should return bad request with invalid JSON" do
        test_body = '"bar":"foo"}'
        env = Rack::MockRequest.env_for "/", {:method => "POST", :input => test_body, "CONTENT_TYPE" => 'application/json'}
        app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, []] }
        response = Rack::Lint.new(Rack::PostBodyContentTypeParser.new(app)).call(env)

        assert_failed_to_parse_as_json(response)
      end
    end
  end

  def params_for_request(body, content_type, &block)
    params = nil
    env = Rack::MockRequest.env_for "/", {:method => "POST", :input => body, "CONTENT_TYPE" => content_type}
    app = lambda { |env| params = Rack::Request.new(env).POST; [200, {'Content-Type' => 'text/plain'}, []] }
    Rack::Lint.new(Rack::PostBodyContentTypeParser.new(app, &block)).call(env)
    params
  end

rescue LoadError => e
  # Missing dependency JSON, skipping tests.
  STDERR.puts "WARN: Skipping Rack::PostBodyContentTypeParser tests (json not installed)"
end
