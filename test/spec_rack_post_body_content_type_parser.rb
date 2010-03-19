require 'test/spec'
require 'rack/mock'

begin
  require 'rack/contrib/post_body_content_type_parser'

  context "Rack::PostBodyContentTypeParser" do

    specify "should handle requests with POST body Content-Type of application/json" do
      app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env).POST] }
      env = env_for_post_with_headers('/', {'Content_Type'.upcase => 'application/json'}, {:body => "asdf", :status => "12"}.to_json)
      body = Rack::PostBodyContentTypeParser.new(app).call(env).last
      body['body'].should.equal "asdf"
      body['status'].should.equal "12"
    end

    specify "should change nothing when the POST body content type isn't application/json" do
      app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, Rack::Request.new(env).POST] }
      body = Rack::PostBodyContentTypeParser.new(app).call(Rack::MockRequest.env_for("/", {:method => 'POST', :params => "body=asdf&status=12"})).last
      body['body'].should.equal "asdf"
      body['status'].should.equal "12"
    end

  end

  def env_for_post_with_headers(path, headers, body)
    Rack::MockRequest.env_for(path, {:method => "POST", :input => body}.merge(headers))
  end
rescue LoadError => e
  # Missing dependency JSON, skipping tests.
  STDERR.puts "WARN: Skipping Rack::PostBodyContentTypeParser tests (json not installed)"
end
