require 'test/spec'
require 'rack/mock'

begin
  require 'rack/contrib/post_body_content_type_parser'

  context "Rack::PostBodyContentTypeParser" do

    specify "should parse 'application/json' requests" do
      params = params_for_request '{"key":"value"}', "application/json"
      params['key'].should.equal "value"
    end

    specify "should parse 'application/json; charset=utf-8' requests" do
      params = params_for_request '{"key":"value"}', "application/json; charset=utf-8"
      params['key'].should.equal "value"
    end
    
    specify "should parse 'application/json' requests with empty body" do
      params = params_for_request "", "application/json"
      params.should.equal({})
    end

    specify "shouldn't affect form-urlencoded requests" do
      params = params_for_request("key=value", "application/x-www-form-urlencoded")
      params['key'].should.equal "value"
    end

  end

  def params_for_request(body, content_type)
    env = Rack::MockRequest.env_for "/", {:method => "POST", :input => body, "CONTENT_TYPE" => content_type}
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env).POST] }
    Rack::PostBodyContentTypeParser.new(app).call(env).last
  end
  
rescue LoadError => e
  # Missing dependency JSON, skipping tests.
  STDERR.puts "WARN: Skipping Rack::PostBodyContentTypeParser tests (json not installed)"
end
