require 'test/spec'
require 'rack/mock'
require 'rack/contrib/response_cache'
require 'fileutils'

context Rack::ResponseCache do
  F = ::File

  def request(opts={}, &block)
    Rack::MockRequest.new(Rack::ResponseCache.new(block||@def_app, opts[:cache]||@cache, &opts[:rc_block])).send(opts[:meth]||:get, opts[:path]||@def_path, opts[:headers]||{})
  end

  setup do
    @cache = {}
    @def_disk_cache = F.join(F.dirname(__FILE__), 'response_cache_test_disk_cache')
    @def_value = ["rack-response-cache"]
    @def_path = '/path/to/blah'
    @def_app = lambda { |env| [200, {'Content-Type' => env['CT'] || 'text/html'}, @def_value]}
  end
  teardown do
    FileUtils.rm_rf(@def_disk_cache)
  end

  specify "should cache results to disk if cache is a string" do
    request(:cache=>@def_disk_cache)
    F.read(F.join(@def_disk_cache, 'path', 'to', 'blah.html')).should.equal @def_value.first
    request(:path=>'/path/3', :cache=>@def_disk_cache)
    F.read(F.join(@def_disk_cache, 'path', '3.html')).should.equal @def_value.first
  end

  specify "should cache results to given cache if cache is not a string" do
    request
    @cache.should.equal('/path/to/blah.html'=>@def_value)
    request(:path=>'/path/3')
    @cache.should.equal('/path/to/blah.html'=>@def_value, '/path/3.html'=>@def_value)
  end

  specify "should not CACHE RESults if request method is not GET" do
    request(:meth=>:post)
    @cache.should.equal({})
    request(:meth=>:put)
    @cache.should.equal({})
    request(:meth=>:delete)
    @cache.should.equal({})
  end

  specify "should not cache results if there is a query string" do
    request(:path=>'/path/to/blah?id=1')
    @cache.should.equal({})
    request(:path=>'/path/to/?id=1')
    @cache.should.equal({})
    request(:path=>'/?id=1')
    @cache.should.equal({})
  end

  specify "should cache results if there is an empty query string" do
    request(:path=>'/?')
    @cache.should.equal('/index.html'=>@def_value)
  end

  specify "should not cache results if the request is not sucessful (status 200)" do
    request{|env| [404, {'Content-Type' => 'text/html'}, ['']]}
    @cache.should.equal({})
    request{|env| [500, {'Content-Type' => 'text/html'}, ['']]}
    @cache.should.equal({})
    request{|env| [302, {'Content-Type' => 'text/html'}, ['']]}
    @cache.should.equal({})
  end

  specify "should not cache results if the block returns nil or false" do
    request(:rc_block=>proc{false})
    @cache.should.equal({})
    request(:rc_block=>proc{nil})
    @cache.should.equal({})
  end

  specify "should cache results to path returned by block" do
    request(:rc_block=>proc{"1"})
    @cache.should.equal("1"=>@def_value)
    request(:rc_block=>proc{"2"})
    @cache.should.equal("1"=>@def_value, "2"=>@def_value)
  end

  specify "should pass the environment and response to the block" do
    e, r = nil, nil
    request(:rc_block=>proc{|env,res| e, r = env, res; nil})
    e['PATH_INFO'].should.equal @def_path
    e['REQUEST_METHOD'].should.equal 'GET'
    e['QUERY_STRING'].should.equal ''
    r.should.equal([200, {"Content-Type"=>"text/html"}, ["rack-response-cache"]])
  end

  specify "should unescape the path by default" do
    request(:path=>'/path%20with%20spaces')
    @cache.should.equal('/path with spaces.html'=>@def_value)
    request(:path=>'/path%3chref%3e')
    @cache.should.equal('/path with spaces.html'=>@def_value, '/path<href>.html'=>@def_value)
  end

  specify "should cache html, css, and xml responses by default" do
    request(:path=>'/a')
    @cache.should.equal('/a.html'=>@def_value)
    request(:path=>'/b', :headers=>{'CT'=>'text/xml'})
    @cache.should.equal('/a.html'=>@def_value, '/b.xml'=>@def_value)
    request(:path=>'/c', :headers=>{'CT'=>'text/css'})
    @cache.should.equal('/a.html'=>@def_value, '/b.xml'=>@def_value, '/c.css'=>@def_value)
  end

  specify "should cache responses by default with the extension added if not already present" do
    request(:path=>'/a.html')
    @cache.should.equal('/a.html'=>@def_value)
    request(:path=>'/b.xml', :headers=>{'CT'=>'text/xml'})
    @cache.should.equal('/a.html'=>@def_value, '/b.xml'=>@def_value)
    request(:path=>'/c.css', :headers=>{'CT'=>'text/css'})
    @cache.should.equal('/a.html'=>@def_value, '/b.xml'=>@def_value, '/c.css'=>@def_value)
  end

  specify "should not delete existing extensions" do
    request(:path=>'/d.css', :headers=>{'CT'=>'text/html'})
    @cache.should.equal('/d.css.html'=>@def_value)
  end

  specify "should cache html responses with empty basename to index.html by default" do
    request(:path=>'/')
    @cache.should.equal('/index.html'=>@def_value)
    request(:path=>'/blah/')
    @cache.should.equal('/index.html'=>@def_value, '/blah/index.html'=>@def_value)
    request(:path=>'/blah/2/')
    @cache.should.equal('/index.html'=>@def_value, '/blah/index.html'=>@def_value, '/blah/2/index.html'=>@def_value)
  end

  specify "should raise an error if a cache argument is not provided" do
    app = Rack::Builder.new{use Rack::ResponseCache; run lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env).POST]}}
    proc{Rack::MockRequest.new(app).get('/')}.should.raise(ArgumentError)
  end

end
