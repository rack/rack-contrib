require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/evil'
require 'erb'

describe "Rack::Evil" do
  app = lambda do |env|
    template = ERB.new("<%= throw :response, [404, {'Content-Type' => 'text/html'}, 'Never know where it comes from'] %>")
    [200, {'Content-Type' => 'text/plain'}, template.result(binding)]
  end

  specify "should enable the app to return the response from anywhere" do
    status, headers, body = Rack::Evil.new(app).call({})

    status.must_equal 404
    headers['Content-Type'].must_equal 'text/html'
    body.must_equal 'Never know where it comes from'
  end
end
