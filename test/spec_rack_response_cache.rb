# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/response_cache'
require 'fileutils'

describe Rack::ResponseCache do
  def request(opts={}, &block)
    Rack::MockRequest.new(Rack::Lint.new(Rack::ResponseCache.new(block||@def_app, opts[:cache]||@cache, &opts[:rc_block]))).send(opts[:meth]||:get, opts[:path]||@def_path, opts[:headers]||{})
  end

  before do
    @cache = {}
    @def_disk_cache = ::File.join(::File.dirname(__FILE__), 'response_cache_test_disk_cache')
    @def_value = ["rack-response-cache"]
    @def_path = '/path/to/blah'
    @def_app = lambda { |env| [200, {'Content-Type' => env['CT'] || 'text/html'}, @def_value]}
  end
  after do
    FileUtils.rm_rf(@def_disk_cache)
  end

  specify "should cache results to disk if cache is a string" do
    request(:cache=>@def_disk_cache)
    _(::File.read(::File.join(@def_disk_cache, 'path', 'to', 'blah.html'))).must_equal @def_value.first
    request(:path=>'/path/3', :cache=>@def_disk_cache)
    _(::File.read(::File.join(@def_disk_cache, 'path', '3.html'))).must_equal @def_value.first
  end

  specify "should cache results to given cache if cache is not a string" do
    request
    _(@cache).must_equal('/path/to/blah.html'=>@def_value)
    request(:path=>'/path/3')
    _(@cache).must_equal('/path/to/blah.html'=>@def_value, '/path/3.html'=>@def_value)
  end

  specify "should run a case-insenstive lookup of the Content-Type header" do
    body = ['ok']
    request { |env| [200, {'content-type' => 'text/html'}, body]}
    _(@cache).must_equal('/path/to/blah.html'=> body)
    request { |env| [200, {'ConTENT-TyPe' => 'text/html'}, body]}
    _(@cache).must_equal('/path/to/blah.html'=> body)
  end

  specify "should not CACHE RESults if request method is not GET" do
    request(:meth=>:post)
    _(@cache).must_equal({})
    request(:meth=>:put)
    _(@cache).must_equal({})
    request(:meth=>:delete)
    _(@cache).must_equal({})
  end

  specify "should not cache results if there is a query string" do
    request(:path=>'/path/to/blah?id=1')
    _(@cache).must_equal({})
    request(:path=>'/path/to/?id=1')
    _(@cache).must_equal({})
    request(:path=>'/?id=1')
    _(@cache).must_equal({})
  end

  specify "should cache results if there is an empty query string" do
    request(:path=>'/?')
    _(@cache).must_equal('/index.html'=>@def_value)
  end

  specify "should not cache results if the request is not successful (status 200)" do
    request{|env| [404, {'Content-Type' => 'text/html'}, ['']]}
    _(@cache).must_equal({})
    request{|env| [500, {'Content-Type' => 'text/html'}, ['']]}
    _(@cache).must_equal({})
    request{|env| [302, {'Content-Type' => 'text/html'}, ['']]}
    _(@cache).must_equal({})
  end

  specify "should not cache results if the block returns nil or false" do
    request(:rc_block=>proc{false})
    _(@cache).must_equal({})
    request(:rc_block=>proc{nil})
    _(@cache).must_equal({})
  end

  specify "should cache results to path returned by block" do
    request(:rc_block=>proc{"1"})
    _(@cache).must_equal("1"=>@def_value)
    request(:rc_block=>proc{"2"})
    _(@cache).must_equal("1"=>@def_value, "2"=>@def_value)
  end

  specify "should pass the environment and response to the block" do
    e, r = nil, nil
    request(:rc_block=>proc{|env,res| e, r = env, [res[0], res[1].dup, res[2].dup]; nil})
    _(e['PATH_INFO']).must_equal @def_path
    _(e['REQUEST_METHOD']).must_equal 'GET'
    _(e['QUERY_STRING']).must_equal ''
    _(r).must_equal([200, {"Content-Type"=>"text/html"}, ["rack-response-cache"]])
  end

  specify "should unescape the path by default" do
    request(:path=>'/path%20with%20spaces')
    _(@cache).must_equal('/path with spaces.html'=>@def_value)
    request(:path=>'/path%3chref%3e')
    _(@cache).must_equal('/path with spaces.html'=>@def_value, '/path<href>.html'=>@def_value)
  end

  specify "should cache html, css, and xml responses by default" do
    request(:path=>'/a')
    _(@cache).must_equal('/a.html'=>@def_value)
    request(:path=>'/b', :headers=>{'CT'=>'text/xml'})
    _(@cache).must_equal('/a.html'=>@def_value, '/b.xml'=>@def_value)
    request(:path=>'/c', :headers=>{'CT'=>'text/css'})
    _(@cache).must_equal('/a.html'=>@def_value, '/b.xml'=>@def_value, '/c.css'=>@def_value)
  end

  specify "should cache responses by default with the extension added if not already present" do
    request(:path=>'/a.html')
    _(@cache).must_equal('/a.html'=>@def_value)
    request(:path=>'/b.xml', :headers=>{'CT'=>'text/xml'})
    _(@cache).must_equal('/a.html'=>@def_value, '/b.xml'=>@def_value)
    request(:path=>'/c.css', :headers=>{'CT'=>'text/css'})
    _(@cache).must_equal('/a.html'=>@def_value, '/b.xml'=>@def_value, '/c.css'=>@def_value)
  end

  specify "should not delete existing extensions" do
    request(:path=>'/d.css', :headers=>{'CT'=>'text/html'})
    _(@cache).must_equal('/d.css.html'=>@def_value)
  end

  specify "should cache html responses with empty basename to index.html by default" do
    request(:path=>'/')
    _(@cache).must_equal('/index.html'=>@def_value)
    request(:path=>'/blah/')
    _(@cache).must_equal('/index.html'=>@def_value, '/blah/index.html'=>@def_value)
    request(:path=>'/blah/2/')
    _(@cache).must_equal('/index.html'=>@def_value, '/blah/index.html'=>@def_value, '/blah/2/index.html'=>@def_value)
  end

  specify "should raise an error if a cache argument is not provided" do
    app = Rack::Lint.new(Rack::Builder.new{use Rack::ResponseCache; run lambda { |env| [200, {'Content-Type' => 'text/plain'}, []]}})
    _(proc{Rack::MockRequest.new(app).get('/')}).must_raise(ArgumentError)
  end

end
