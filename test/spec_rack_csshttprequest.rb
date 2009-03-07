require 'test/spec'
require 'rack/mock'

begin
  require 'csshttprequest'
  require 'rack/contrib/csshttprequest'

  context "Rack::CSSHTTPRequest" do

    before(:each) do
      @test_body = '{"bar":"foo"}'
      @test_headers = {'Content-Type' => 'text/plain'}
      @encoded_body = CSSHTTPRequest.encode(@test_body)
      @app = lambda { |env| [200, @test_headers, [@test_body]] }
    end

    specify "env['csshttprequest.chr'] should be set to true when \
        PATH_INFO ends with '.chr'" do
      request = Rack::MockRequest.env_for("/blah.chr", :lint => true, :fatal => true)
      Rack::CSSHTTPRequest.new(@app).call(request)
      request['csshttprequest.chr'].should.equal true
    end

    specify "env['csshttprequest.chr'] should be set to true when \
        request parameter _format == 'chr'" do
      request = Rack::MockRequest.env_for("/?_format=chr", :lint => true, :fatal => true)
      Rack::CSSHTTPRequest.new(@app).call(request)
      request['csshttprequest.chr'].should.equal true
    end

    specify "should not change the headers or response when !env['csshttprequest.chr']" do
      request = Rack::MockRequest.env_for("/", :lint => true, :fatal => true)
      status, headers, response = Rack::CSSHTTPRequest.new(@app).call(request)
      headers.should.equal @test_headers
      response.join.should.equal @test_body
    end

    context "when env['csshttprequest.chr']" do
      before(:each) do
        @request = Rack::MockRequest.env_for("/",
          'csshttprequest.chr' => true, :lint => true, :fatal => true)
      end

      specify "should modify the content length to the correct value" do
        headers = Rack::CSSHTTPRequest.new(@app).call(@request)[1]
        headers['Content-Length'].should.equal @encoded_body.length.to_s
      end

      specify "should modify the content type to the correct value" do
        headers = Rack::CSSHTTPRequest.new(@app).call(@request)[1]
        headers['Content-Type'].should.equal 'text/css'
      end

      specify "should not modify any other headers" do
        headers = Rack::CSSHTTPRequest.new(@app).call(@request)[1]
        headers.should.equal @test_headers.merge({
          'Content-Type' => 'text/css',
          'Content-Length' => @encoded_body.length.to_s
        })
      end
    end

  end
rescue LoadError => boom
  STDERR.puts "WARN: Skipping Rack::CSSHTTPRequest tests (nbio-csshttprequest not installed)"
end
