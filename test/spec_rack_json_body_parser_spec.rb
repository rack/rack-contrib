# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/json_body_parser'

describe Rack::JSONBodyParser do

  def app
   ->(env) { [200, {}, [Rack::Request.new(env).params.to_s]] }
  end

  def mock_env(input: '{"key": "value"}', type: 'application/json')
    headers = if type
                { input: input, 'REQUEST_METHOD' => 'POST', 'CONTENT_TYPE' => type }
              else
                { input: input, 'REQUEST_METHOD' => 'POST' }
              end

    Rack::MockRequest.env_for '/', headers
  end

  def create_parser(app, **args, &block)
    Rack::Lint.new(Rack::JSONBodyParser.new(app, **args, &block))
  end

  specify "should parse 'application/json' requests" do
    res = create_parser(app).call(mock_env)
    _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'
  end

  specify "should parse 'application/json; charset=utf-8' requests" do
    env = mock_env(type: 'application/json; charset=utf-8')
    res = create_parser(app).call(env)
    _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'
  end

  specify "should parse 'application/json' requests with an empty body" do
    res = create_parser(app).call(mock_env(input: ''))
    _(res[2].to_enum.to_a.join).must_equal '{}'
  end

  specify "shouldn't affect form-urlencoded requests" do
    env = mock_env(input: 'key=value', type: 'application/x-www-form-urlencoded')
    res = create_parser(app).call(env)
    _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'
  end

  specify "should not parse non-json media types" do
    env = mock_env(type: 'text/plain')
    res = create_parser(app).call(env)
    _(res[2].to_enum.to_a.join).must_equal '{}'
  end

  specify "shouldn't parse or error when CONTENT_TYPE is nil" do
    env = mock_env(type: nil)
    res = create_parser(app).call(env)
    _(res[2].to_enum.to_a.join).must_equal %Q({"{\\"key\\": \\"value\\"}"=>nil})
  end

  specify "should not create additions" do
    before = Symbol.all_symbols
    env = mock_env(input: %{{"json_class":"this_should_not_be_added"}})
    create_parser(app).call(env)
    result = Symbol.all_symbols - before
    _(result).must_be_empty
  end

  specify "should not rescue JSON:ParserError raised by the app" do
    env = mock_env
    app = ->(env) { raise JSON::ParserError }
    _( -> { create_parser(app).call(env) }).must_raise JSON::ParserError
  end

  describe "contradiction between body and type" do
    specify "should return bad request with a JSON-encoded error message" do
      env = mock_env(input: 'This is not JSON')
      status, headers, body = create_parser(app).call(env)
      _(status).must_equal 400
      _(headers['Content-Type']).must_equal 'application/json'
      body.each { |part| _(JSON.parse(part)['error']).wont_be_nil }
    end
  end

  describe "with configuration" do
    specify "should use a given block to parse the JSON body" do
      parser = create_parser(app) do |body|
        { 'payload' => JSON.parse(body) }
      end
      res = parser.call(mock_env)
      _(res[2].to_enum.to_a.join).must_equal '{"payload"=>{"key"=>"value"}}'
    end

    specify "should accept an array of HTTP verbs to parse" do
      env = mock_env.merge('REQUEST_METHOD' => 'GET')
      parser = create_parser(app, verbs: %w[GET])

      res = parser.call(env)
      _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'

      res = parser.call(mock_env)
      _(res[2].to_enum.to_a.join).must_equal '{}'
    end

    specify "should accept an Array of media-types to parse" do
      parser = create_parser(app, media: ['application/json', 'text/plain'])
      env = mock_env(type: 'text/plain')
      res = parser.call(env)
      _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'

      html_env = mock_env(type: 'text/html')
      res = parser.call(html_env)
      _(res[2].to_enum.to_a.join).must_equal '{}'
    end

    specify "should accept a Regexp as a media-type matcher" do
      parser = create_parser(app, media: /json/)
      env = mock_env(type: 'weird/json.odd')
      res = parser.call(env)
      _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'
    end

    specify "should accept a String as a media-type matcher" do
      parser = create_parser(app, media: 'application/vnd.api+json')
      env = mock_env(type: 'application/vnd.api+json')
      res = parser.call(env)
      _(res[2].to_enum.to_a.join).must_equal '{"key"=>"value"}'
    end
  end
end
