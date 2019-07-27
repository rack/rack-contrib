require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/json_body_parser'

describe Rack::JSONBodyParser do
  def app
    ->(env) { Rack::Request.new(env).POST }
  end

  def echo(body, type:, verb: 'POST', parser: Rack::JSONBodyParser.new(app))
    env = Rack::MockRequest.env_for '/', method: verb, input: body, 'CONTENT_TYPE' => type
    parser.call(env)
  end

  specify "should parse 'application/json' requests" do
    params = echo '{"key":"value"}', type: "application/json"
    params['key'].must_equal "value"
  end

  specify "should parse 'application/json; charset=utf-8' requests" do
    params = echo '{"key":"value"}', type: "application/json; charset=utf-8"
    params['key'].must_equal "value"
  end

  specify "should parse 'application/json' requests with empty body" do
    params = echo "", type: "application/json"
    params.must_equal({})
  end

  specify "shouldn't affect form-urlencoded requests" do
    params = echo "key=value", type: "application/x-www-form-urlencoded"
    params['key'].must_equal "value"
  end

  specify "shouldn't parse or error when CONTENT_TYPE is nil" do
    params = echo '{"key":"value"}', type: nil
    assert_nil(params['key'])
  end

  specify "should not create additions" do
    before = Symbol.all_symbols
    echo %{{"json_class":"this_should_not_be_added"}}, type: "application/json"
    result = Symbol.all_symbols - before
    result.must_be_empty
  end

  specify "should apply given block to a JSON body" do
    parser = Rack::JSONBodyParser.new(app) do |body|
      { 'payload' => JSON.parse(body) }
    end
    params = echo '{"key":"value"}', type: "application/json", parser: parser
    params['payload'].wont_be_nil
    params['payload']['key'].must_equal "value"
  end

  describe "with a loose media_type_matcher" do
    specify "should match any header containing 'json'" do
      loose_parser = Rack::JSONBodyParser.new(app, media_type_matcher: :loose)
      params = echo(
        '{"key":"value"}',
        type: "application/vnd.api+json",
        parser: loose_parser
      )
      params['key'].must_equal "value"
    end

    specify "shouldn't parse or error when CONTENT_TYPE is nil" do
      loose_parser = Rack::JSONBodyParser.new(app, media_type_matcher: :loose)
      params = echo '{"key":"value"}', type: nil, parser: loose_parser
      assert_nil(params['key'])
    end
  end

  specify "should accept a custom media matcher callable" do
    custom_parser = Rack::JSONBodyParser.new(
      app,
      media_type_matcher: ->(env) { env['CONTENT_TYPE'] == 'custom' }
    )
    params = echo '{"key":"value"}', type: 'custom', parser: custom_parser
    params['key'].must_equal "value"
  end

  describe "should skip parsing for some HTTP verbs" do
    body = '{"key":"value"}'

    specify "should ignore GET|OPTIONS|HEAD|TRACE requests by default" do
      %w[GET OPTIONS HEAD CONNECT TRACE].each do |verb|
        params = echo body, type: 'application/json', verb: verb
        assert_nil(params['key'])
      end
    end

    specify "should allow overriding the HTTP verbs that get parsed" do
      parser = Rack::JSONBodyParser.new(app, verbs: %w[DELETE])
      params = echo body, type: 'application/json', verb: 'DELETE', parser: parser
      params['key'].must_equal 'value'
    end
  end

  describe "contradiction between body and type" do
    def assert_failed_to_parse_as_json(response)
      response.wont_be_nil
      status, headers, body = response
      status.must_equal 400
      body.each { |part| part.must_equal "failed to parse body as JSON" }
    end

    specify "should return bad request with invalid JSON" do
      test_body = '"bar":"foo"}'
      response = echo test_body, type: 'application/json'
      assert_failed_to_parse_as_json(response)
    end
  end
end
