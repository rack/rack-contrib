# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/contrib/runtime'

describe "Rack::Runtime" do
  specify "exists and sets X-Runtime header" do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    response = Rack::Runtime.new(app).call({})
    if Rack.release < "3"
      _(response[1]['X-Runtime']).must_match /[\d\.]+/
    else
      _(response[1]['x-runtime']).must_match /[\d\.]+/
    end
  end
end
