# -*- encoding : us-ascii -*-

require 'minitest/autorun'
require 'rack/contrib/enforce_valid_encoding'

if "a string".respond_to?(:valid_encoding?)
  require 'rack/mock'
  require 'rack/contrib/enforce_valid_encoding'

  VALID_PATH = "h%C3%A4ll%C3%B2"
  INVALID_PATH = "/%D1%A1%D4%F1%D7%A2%B2%E1%D3%C3%BB%A7%C3%FB"

  describe "Rack::EnforceValidEncoding" do
    before do
      @app = Rack::EnforceValidEncoding.new(lambda { |env|
        [200, {'Content-Type'=>'text/plain'}, ['Hello World']]
      })
    end

    describe "contstant assertions" do
      it "INVALID_PATH should not be a valid UTF-8 string when decoded" do
        Rack::Utils.unescape(INVALID_PATH).valid_encoding?.must_equal false
      end

      it "VALID_PATH should be valid when decoded" do
        Rack::Utils.unescape(VALID_PATH).valid_encoding?.must_equal true
      end
    end

    it "should accept a request with a correctly encoded path" do
      response = Rack::MockRequest.new(@app).get(VALID_PATH)
      response.body.must_equal("Hello World")
      response.status.must_equal(200)
    end

    it "should reject a request with a poorly encoded path" do
      response = Rack::MockRequest.new(@app).get(INVALID_PATH)
      response.status.must_equal(400)
    end

    it "should accept a request with a correctly encoded query string" do
      response = Rack::MockRequest.new(@app).get('/', 'QUERY_STRING' => VALID_PATH)
      response.body.must_equal("Hello World")
      response.status.must_equal(200)
    end

    it "should reject a request with a poorly encoded query string" do
      response = Rack::MockRequest.new(@app).get('/', 'QUERY_STRING' => INVALID_PATH)
      response.status.must_equal(400)
    end

    it "should reject a request containing malformed multibyte characters" do
      response = Rack::MockRequest.new(@app).get('/', 'QUERY_STRING' => Rack::Utils.unescape(INVALID_PATH, Encoding::ASCII_8BIT))
      response.status.must_equal(400)
    end
  end
else
  STDERR.puts "WARN: Skipping Rack::EnforceValidEncoding tests (String#valid_encoding? not available)"
end
