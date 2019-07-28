require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/json_body_parser'

describe Rack::JSONBodyParser do
  APP = ->(env) { Rack::Request.new(env).params }

  def mock_env(input: '{"key": "value"}', type: 'application/json')
    Rack::MockRequest.env_for '/', input: input, 'REQUEST_METHOD' => 'POST',
      'CONTENT_TYPE' => type
  end

  def create_parser(**args, &block)
    Rack::JSONBodyParser.new(APP, **args, &block)
  end

  def app
    ->(env) { Rack::Request.new(env).POST }
  end

  specify "should parse 'application/json' requests" do
    res = create_parser.call(mock_env)
    res['key'].must_equal "value"
  end

  specify "should parse 'application/json; charset=utf-8' requests" do
    env = mock_env(type: 'application/json; charset=utf-8')
    res = create_parser.call(env)
    res['key'].must_equal "value"
  end

  specify "should parse 'application/json' requests with an empty body" do
    res = create_parser.call(mock_env(input: ''))
    res.must_equal({})
  end

  specify "shouldn't affect form-urlencoded requests" do
    env = mock_env(input: 'key=value', type: 'application/x-www-form-urlencoded')
    res = create_parser.call(env)
    res['key'].must_equal "value"
  end

  specify "should not parse non-json media types" do
    env = mock_env(type: 'text/plain')
    res = create_parser.call(env)
    res['key'].must_be_nil
  end

  specify "shouldn't parse or error when CONTENT_TYPE is nil" do
    env = mock_env(type: nil)
    res = create_parser.call(env)
    assert_nil(res['key'])
  end

  specify "should not create additions" do
    before = Symbol.all_symbols
    env = mock_env(input: %{{"json_class":"this_should_not_be_added"}})
    res = create_parser.call(env)
    result = Symbol.all_symbols - before
    result.must_be_empty
  end

  describe "contradiction between body and type" do
    specify "should return bad request with a JSON-encoded error message" do
      env = mock_env(input: 'This is not JSON')
      status, headers, body = create_parser.call(env)
      status.must_equal 400
      headers['Content-Type'].must_equal 'application/json'
      body.each { |part| JSON.parse(part)['error'].wont_be_nil }
    end
  end

  describe "with configuration" do
    specify "should use a given block to parse the JSON body" do
      parser = create_parser do |body|
        { 'payload' => JSON.parse(body) }
      end
      res = parser.call(mock_env)
      res['payload'].wont_be_nil
      res['payload']['key'].must_equal "value"
    end

    specify "should accept an array of HTTP verbs to parse" do
      env = mock_env.merge('REQUEST_METHOD' => 'GET')
      parser = create_parser(verbs: %w[GET])

      res_via_get = parser.call(env)
      res_via_post = parser.call(mock_env)

      res_via_get['key'].must_equal 'value'
      res_via_post['key'].must_be_nil
    end

    specify "should accept an Array of media-types to parse" do
      parser = create_parser(media: ['application/json', 'text/plain'])
      env = mock_env(type: 'text/plain')
      res = parser.call(env)
      res['key'].must_equal 'value'

      html_env = mock_env(type: 'text/html')
      html_res = parser.call(html_env)
      html_res['key'].must_be_nil
    end

    specify "should accept a Regexp as a media-type matcher" do
      parser = create_parser(media: /json/)
      env = mock_env(type: 'weird/json.odd')
      res = parser.call(env)
      res['key'].must_equal 'value'
    end

    specify "should accept a String as a media-type matcher" do
      parser = create_parser(media: 'application/vnd.api+json')
      env = mock_env(type: 'application/vnd.api+json')
      res = parser.call(env)
      res['key'].must_equal 'value'
    end
  end
end
