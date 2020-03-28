require 'minitest/autorun'

require 'rack'
require 'rack/contrib/static_cache'
require 'rack/mock'
require 'timecop'

class DummyApp
  def call(env)
    [200, {}, ["Hello World"]]
  end
end

describe "Rack::StaticCache" do
  def static_root
    ::File.expand_path(::File.dirname(__FILE__))
  end

  def request(options)
    Rack::MockRequest.new(build_middleware(options))
  end

  def build_middleware(options)
    options = { :root => static_root }.merge(options)
    Rack::StaticCache.new(DummyApp.new, options)
  end

  describe "with a default app request" do
    def get_request(path)
      request(:urls => ["/statics"]).get(path)
    end

    it "should serve the request successfully" do
      _(get_request("/statics/test").ok?).must_equal(true)
    end

    it "should serve the correct file contents" do
      _(get_request("/statics/test").body).must_match(/rubyrack/)
    end

    it "should serve the correct file contents for a file with an extension" do
      _(get_request("/statics/test.html").body).must_match(/extensions rule!/)
    end

    it "should set a long Cache-Control max-age" do
      _(get_request("/statics/test").headers['Cache-Control']).must_equal 'max-age=31536000, public'
    end

    it "should set a long-distant Expires header" do
      next_year = Time.now().year + 1
      _(get_request("/statics/test").headers['Expires']).must_match(
        Regexp.new(
          "[A-Z][a-z]{2}[,][\s][0-9]{2}[\s][A-Z][a-z]{2}[\s]" <<
          "#{next_year}" <<
          "[\s][0-9]{2}[:][0-9]{2}[:][0-9]{2} GMT$"
        )
      )
    end

    it "should set Expires header based on current UTC time" do
      Timecop.freeze(DateTime.parse("2020-03-28 23:51 UTC")) do
        _(get_request("/statics/test").headers['Expires']).must_match("Sun, 28 Mar 2021 23:51:00 GMT") # now + 1 year
      end
    end

    it "should not cache expiration date between requests" do
      middleware = build_middleware(:urls => ["/statics"])

      Timecop.freeze(DateTime.parse("2020-03-28 23:41 UTC")) do
        r = Rack::MockRequest.new(middleware)
        _(r.get("/statics/test").headers["Expires"]).must_equal "Sun, 28 Mar 2021 23:41:00 GMT" # time now + 1 year
      end

      Timecop.freeze(DateTime.parse("2020-03-28 23:51 UTC")) do
        r = Rack::MockRequest.new(middleware)
        _(r.get("/statics/test").headers["Expires"]).must_equal "Sun, 28 Mar 2021 23:51:00 GMT" # time now + 1 year
      end
    end

    it "should set Date header with current GMT time" do
      Timecop.freeze(DateTime.parse('2020-03-28 22:51 UTC')) do
        _(get_request("/statics/test").headers['Date']).must_equal 'Sat, 28 Mar 2020 22:51:00 GMT'
      end
    end

    it "should return 404s if url root is known but it can't find the file" do
      _(get_request("/statics/non-existent").not_found?).must_equal(true)
    end

    it "should call down the chain if url root is not known" do
      res = get_request("/something/else")
      _(res.ok?).must_equal(true)
      _(res.body).must_equal "Hello World"
    end

    it "should serve files if requested with version number" do
      res = get_request("/statics/test-0.0.1")
      _(res.ok?).must_equal(true)
    end

    it "should serve the correct file contents for a file with an extension requested with a version" do
      _(get_request("/statics/test-0.0.1.html").body).must_match(/extensions rule!/)
    end
  end

  describe "with a custom version number regex" do
    def get_request(path)
      request(:urls => ["/statics"], :version_regex => /-[0-9a-f]{8}/).get(path)
    end

    it "should handle requests with the custom regex" do
      _(get_request("/statics/test-deadbeef").ok?).must_equal(true)
    end

    it "should handle extensioned requests for the custom regex" do
      _(get_request("/statics/test-deadbeef.html").body).must_match(/extensions rule!/)
    end

    it "should not handle requests for the default version regex" do
      _(get_request("/statics/test-0.0.1").ok?).must_equal(false)
    end
  end

  describe "with custom cache duration" do
    def get_request(path)
      request(:urls => ["/statics"], :duration => 2).get(path)
    end

    it "should change cache duration" do
      next_next_year = Time.now().year + 2
      _(get_request("/statics/test").headers['Expires']).must_match(Regexp.new("#{next_next_year}"))
    end
  end

  describe "with partial-year cache duration" do
    def get_request(path)
      request(:urls => ["/statics"], :duration => 1.0 / 52).get(path)
    end

    it "should round max-age if duration is part of a year" do
      _(get_request("/statics/test").headers['Cache-Control']).must_equal "max-age=606461, public"
    end
  end

  describe "with versioning disabled" do
    def get_request(path)
      request(:urls => ["/statics"], :versioning => false).get(path)
    end

    it "should return 404s if requested with version number" do
      _(get_request("/statics/test-0.0.1").not_found?).must_equal(true)
    end
  end

  describe "with * suffix on directory name" do
    def get_request(path)
      request(:urls => ["/statics*"]).get(path)
    end

    it "should serve files OK" do
      _(get_request("/statics/test").ok?).must_equal(true)
    end

    it "should serve the content" do
      _(get_request("/statics/test").body).must_match(/rubyrack/)
    end

    it "should not set a max-age" do
      _(get_request("/statics/test").headers['Cache-Control']).must_be_nil
    end

    it "should not set an Expires header" do
      _(get_request("/statics/test").headers['Expires']).must_be_nil
    end
  end
end
