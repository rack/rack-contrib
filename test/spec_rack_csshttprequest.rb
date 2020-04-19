require 'minitest/autorun'
require 'rack/mock'

begin
  require 'csshttprequest'
  require 'rack/contrib/csshttprequest'

  describe "Rack::CSSHTTPRequest" do
    def css_httl_request(app)
      Rack::Lint.new(Rack::CSSHTTPRequest.new(app))
    end

    before(:each) do
      @test_body = '{"bar":"foo"}'
      @test_headers = {'Content-Type' => 'text/plain'}
      @encoded_body = CSSHTTPRequest.encode(@test_body)
      @app = lambda { |env| [200, @test_headers, [@test_body]] }
    end

    specify "env['csshttprequest.chr'] should be set to true when \
        PATH_INFO ends with '.chr'" do
      request = Rack::MockRequest.env_for("/blah.chr", :fatal => true)
      css_httl_request(@app).call(request)
      _(request['csshttprequest.chr']).must_equal true
    end

    specify "env['csshttprequest.chr'] should be set to true when \
        request parameter _format == 'chr'" do
      request = Rack::MockRequest.env_for("/?_format=chr", :fatal => true)
      css_httl_request(@app).call(request)
      _(request['csshttprequest.chr']).must_equal true
    end

    specify "should not change the headers or response when !env['csshttprequest.chr']" do
      request = Rack::MockRequest.env_for("/", :fatal => true)
      status, headers, body = css_httl_request(@app).call(request)
      _(headers).must_equal @test_headers
      _(body.to_enum.to_a.join).must_equal @test_body
    end

    describe "when env['csshttprequest.chr']" do
      before(:each) do
        @request = Rack::MockRequest.env_for("/",
          'csshttprequest.chr' => true, :fatal => true)
      end

      specify "should modify the content length to the correct value" do
        headers = css_httl_request(@app).call(@request)[1]
        _(headers['Content-Length']).must_equal @encoded_body.length.to_s
      end

      specify "should modify the content type to the correct value" do
        headers = css_httl_request(@app).call(@request)[1]
        _(headers['Content-Type']).must_equal 'text/css'
      end

      specify "should not modify any other headers" do
        headers = css_httl_request(@app).call(@request)[1]
        _(headers).must_equal @test_headers.merge({
          'Content-Type' => 'text/css',
          'Content-Length' => @encoded_body.length.to_s
        })
      end
    end

  end
rescue LoadError => boom
  STDERR.puts "WARN: Skipping Rack::CSSHTTPRequest tests (nbio-csshttprequest not installed)"
end
