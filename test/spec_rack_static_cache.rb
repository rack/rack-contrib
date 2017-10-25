require 'minitest/autorun'

require 'rack'
require 'rack/contrib/static_cache'
require 'rack/mock'

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
    options = { :root => static_root }.merge(options)
    Rack::MockRequest.new(Rack::StaticCache.new(DummyApp.new, options))
  end

  describe "with a default app request" do
    def get_request(path)
      request(:urls => ["/statics"]).get(path)
    end

    it "should serve the request successfully" do
      get_request("/statics/test").ok?.must_equal(true)
    end

    it "should serve the correct file contents" do
      get_request("/statics/test").body.must_match(/rubyrack/)
    end

    it "should serve the correct file contents for a file with an extension" do
      get_request("/statics/test.html").body.must_match(/extensions rule!/)
    end

    it "should set a long Cache-Control max-age" do
      get_request("/statics/test").headers['Cache-Control'].must_equal 'max-age=31536000, public'
    end

    it "should set a long-distant Expires header" do
      next_year = Time.now().year + 1
      get_request("/statics/test").headers['Expires'].must_match(
        Regexp.new(
          "[A-Z][a-z]{2}[,][\s][0-9]{2}[\s][A-Z][a-z]{2}[\s]" <<
          "#{next_year}" <<
          "[\s][0-9]{2}[:][0-9]{2}[:][0-9]{2} GMT$"
        )
      )
    end

    it "should return 404s if url root is known but it can't find the file" do
      get_request("/statics/non-existent").not_found?.must_equal(true)
    end

    it "should call down the chain if url root is not known" do
      res = get_request("/something/else")
      res.ok?.must_equal(true)
      res.body.must_equal "Hello World"
    end

    it "should serve files if requested with version number" do
      res = get_request("/statics/test-0.0.1")
      res.ok?.must_equal(true)
    end

    it "should serve the correct file contents for a file with an extension requested with a version" do
      get_request("/statics/test-0.0.1.html").body.must_match(/extensions rule!/)
    end
  end

  describe "with a custom version number regex" do
    def get_request(path)
      request(:urls => ["/statics"], :version_regex => /-[0-9a-f]{8}/).get(path)
    end

    it "should handle requests with the custom regex" do
      get_request("/statics/test-deadbeef").ok?.must_equal(true)
    end

    it "should handle extensioned requests for the custom regex" do
      get_request("/statics/test-deadbeef.html").body.must_match(/extensions rule!/)
    end

    it "should not handle requests for the default version regex" do
      get_request("/statics/test-0.0.1").ok?.must_equal(false)
    end
  end

  describe "with custom cache duration" do
    def get_request(path)
      request(:urls => ["/statics"], :duration => 2).get(path)
    end

    it "should change cache duration" do
      next_next_year = Time.now().year + 2
      get_request("/statics/test").headers['Expires'].must_match(Regexp.new("#{next_next_year}"))
    end
  end

  describe "with partial-year cache duration" do
    def get_request(path)
      request(:urls => ["/statics"], :duration => 1.0 / 52).get(path)
    end

    it "should round max-age if duration is part of a year" do
      get_request("/statics/test").headers['Cache-Control'].must_equal "max-age=606461, public"
    end
  end

  describe "with versioning disabled" do
    def get_request(path)
      request(:urls => ["/statics"], :versioning => false).get(path)
    end

    it "should return 404s if requested with version number" do
      get_request("/statics/test-0.0.1").not_found?.must_equal(true)
    end
  end

  describe "with * suffix on directory name" do
    def get_request(path)
      request(:urls => ["/statics*"]).get(path)
    end

    it "should serve files OK" do
      get_request("/statics/test").ok?.must_equal(true)
    end

    it "should serve the content" do
      get_request("/statics/test").body.must_match(/rubyrack/)
    end

    it "should not set a max-age" do
      get_request("/statics/test").headers['Cache-Control'].must_be_nil
    end

    it "should not set an Expires header" do
      get_request("/statics/test").headers['Expires'].must_be_nil
    end
  end
end
