require 'rack/mock'
require 'rack/contrib/csshttprequest'

context "Rack::CSSHTTPRequest" do
  
  specify "should modify the content length to the correct value" do
    test_body = '{"bar":"foo"}'
    encoded_body = CSSHTTPRequest.encode(test_body)
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, test_body] }
    request = Rack::MockRequest.env_for("/")
    headers = Rack::CSSHTTPRequest.new(app).call(request)[1]
    headers['Content-Length'].should == (encoded_body.length).to_s
  end
  
  specify "should modify the content type to the correct value" do
    test_body = '{"bar":"foo"}'
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, test_body] }
    request = Rack::MockRequest.env_for("/")
    headers = Rack::CSSHTTPRequest.new(app).call(request)[1]
    headers['Content-Type'].should == 'text/css'
  end
end
