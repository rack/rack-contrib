# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/evil'
require 'erb'

describe "Rack::Evil" do
  app = lambda do |env|
    template = ERB.new("<%= throw :response, [404, {'Content-Type' => 'text/html'}, ['Never know where it comes from']] %>")
    [200, {'Content-Type' => 'text/plain'}, template.result(binding)]
  end

  env = Rack::MockRequest.env_for('', {})

  specify "should enable the app to return the response from anywhere" do
    status, headers, body = Rack::Lint.new(Rack::Evil.new(app)).call(env)

    _(status).must_equal 404
    _(headers['Content-Type']).must_equal 'text/html'
    _(body.to_enum.to_a).must_equal ['Never know where it comes from']
  end
end
