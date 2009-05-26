require 'test/spec'

require 'rack'
require 'rack/contrib/static_cache'
require 'rack/mock'

class DummyApp
  def call(env)
    [200, {}, ["Hello World"]]
  end
end

describe "Rack::StaticCache" do

  setup do
    @root = ::File.expand_path(::File.dirname(__FILE__))
  end

  it "should serve files with required headers" do
    default_app_request
    res = @request.get("/statics/test")
    res.should.be.ok
    res.body.should =~ /rubyrack/
    res.headers['Cache-Control'].should == 'max-age=31536000, public'
     next_year = Time.now().year + 1
    res.headers['Expires'].should =~ Regexp.new(
        "[A-Z][a-z]{2}[,][\s][0-9]{2}[\s][A-Z][a-z]{2}[\s]" << "#{next_year}" <<
        "[\s][0-9]{2}[:][0-9]{2}[:][0-9]{2} GMT$")
    res.headers.has_key?('Etag').should == false
    res.headers.has_key?('Pragma').should == false
    res.headers.has_key?('Last-Modified').should == false
  end

  it "should return 404s if url root is known but it can't find the file" do
    default_app_request
    res = @request.get("/statics/foo")
    res.should.be.not_found
  end

  it "should call down the chain if url root is not known" do
    default_app_request
    res = @request.get("/something/else")
    res.should.be.ok
    res.body.should == "Hello World"
  end

  it "should serve files if requested with version number and versioning is enabled" do
    default_app_request
    res = @request.get("/statics/test-0.0.1")
    res.should.be.ok
  end

  it "should change cache duration if specified thorugh option" do
    configured_app_request
    res = @request.get("/statics/test")
    res.should.be.ok
    res.body.should =~ /rubyrack/
    next_next_year = Time.now().year + 2
    res.headers['Expires'].should =~ Regexp.new("#{next_next_year}")
  end

  it "should return 404s if requested with version number but versioning is disabled" do
    configured_app_request
    res = @request.get("/statics/test-0.0.1")
    res.should.be.not_found
  end

  it "should serve files with plain headers when * is added to the directory name" do
    configured_app_request
    res = @request.get("/documents/test")
    res.should.be.ok
    res.body.should =~ /nocache/
    next_next_year = Time.now().year + 2
    res.headers['Expires'].should.not =~ Regexp.new("#{next_next_year}")
  end

  def default_app_request
    @options = {:urls => ["/statics"], :root => @root}
    request
  end

  def configured_app_request
    @options = {:urls => ["/statics", "/documents*"], :root => @root, :versioning => false, :duration => 2}
    request
  end

  def request
    @request = Rack::MockRequest.new(Rack::StaticCache.new(DummyApp.new, @options))
  end

end
