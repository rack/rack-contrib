require 'test/spec'
require 'rack/mock'
require 'rack/contrib/relative_redirect'
require 'fileutils'

context Rack::RelativeRedirect do
  def request(opts={}, &block)
    @def_status = opts[:status] if opts[:status]
    @def_location = opts[:location] if opts[:location]
    yield Rack::MockRequest.new(Rack::RelativeRedirect.new(@def_app, &opts[:block])).get(opts[:path]||@def_path, opts[:headers]||{})
  end

  setup do
    @def_path = '/path/to/blah'
    @def_status = 301
    @def_location = '/redirect/to/blah'
    @def_app = lambda { |env| [@def_status, {'Location' => @def_location}, [""]]}
  end

  specify "should make the location url an absolute url if currently a relative url" do
    request do |r|
      r.status.should.equal(301)
      r.headers['Location'].should.equal('http://example.org/redirect/to/blah')
    end
    request(:status=>302, :location=>'/redirect') do |r|
      r.status.should.equal(302)
      r.headers['Location'].should.equal('http://example.org/redirect')
    end
  end

  specify "should use the request path if the relative url is given and doesn't start with a slash" do
    request(:status=>303, :location=>'redirect/to/blah') do |r|
      r.status.should.equal(303)
      r.headers['Location'].should.equal('http://example.org/path/to/redirect/to/blah')
    end
    request(:status=>303, :location=>'redirect') do |r|
      r.status.should.equal(303)
      r.headers['Location'].should.equal('http://example.org/path/to/redirect')
    end
  end

  specify "should use a given block to make the url absolute" do
    request(:block=>proc{|env, res| "https://example.org"}) do |r|
      r.status.should.equal(301)
      r.headers['Location'].should.equal('https://example.org/redirect/to/blah')
    end
    request(:status=>303, :location=>'/redirect', :block=>proc{|env, res| "https://e.org:9999/blah"}) do |r|
      r.status.should.equal(303)
      r.headers['Location'].should.equal('https://e.org:9999/blah/redirect')
    end
  end

  specify "should not modify the location url unless the response is a redirect" do
    status = 200
    @def_app = lambda { |env| [status, {'Content-Type' => "text/html"}, [""]]}
    request do |r|
      r.status.should.equal(200)
      r.headers.should.not.include?('Location')
    end
    status = 404
    @def_app = lambda { |env| [status, {'Content-Type' => "text/html", 'Location' => 'redirect'}, [""]]}
    request do |r|
      r.status.should.equal(404)
      r.headers['Location'].should.equal('redirect')
    end
  end

  specify "should not modify the location url if it is already an absolute url" do
    request(:location=>'https://example.org/') do |r|
      r.status.should.equal(301)
      r.headers['Location'].should.equal('https://example.org/')
    end
    request(:status=>302, :location=>'https://e.org:9999/redirect') do |r|
      r.status.should.equal(302)
      r.headers['Location'].should.equal('https://e.org:9999/redirect')
    end
  end
end
