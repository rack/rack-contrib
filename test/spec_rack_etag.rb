require 'test/spec'
require 'rack/mock'
require 'rack/contrib/etag'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'

context "Rack::ETag" do

  body   = 'Hello, World!'
  
  context('if no ETag is set on a String body') do
    before(:each) do
      @app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, body] }
    end
    specify 'sets ETag' do
      response = Rack::ETag.new(@app).call({})
      response[1]['ETag'].should.equal "\"#{Digest::MD5.hexdigest(body)}\""
    end
    specify 'uses SHA-1 if specified' do
      response = Rack::ETag.new(@app, :sha1).call({})
      response[1]['ETag'].should.equal "\"#{Digest::SHA1.hexdigest(body)}\""
    end
    specify 'uses SHA-256 if specified' do
      response = Rack::ETag.new(@app, :sha256).call({})
      response[1]['ETag'].should.equal "\"#{Digest::SHA2.hexdigest(body)}\""
    end
    specify 'uses SHA-384 if specified' do
      response = Rack::ETag.new(@app, :sha384).call({})
      response[1]['ETag'].should.equal "\"#{(Digest::SHA2.new(384) << body).to_s}\""
    end
    specify 'uses SHA-512 if specified' do
      response = Rack::ETag.new(@app, :sha512).call({})
      response[1]['ETag'].should.equal "\"#{(Digest::SHA2.new(512) << body).to_s}\""
    end
  end

  specify "does not change ETag if it is already set" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain', 'ETag' => '"abc"'}, "Hello, World!"] }
    response = Rack::ETag.new(app).call({})
    response[1]['ETag'].should.equal "\"abc\""
  end

  specify "does not set ETag if streaming body" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello", "World"]] }
    response = Rack::ETag.new(app).call({})
    response[1]['ETag'].should.equal nil
  end
end
