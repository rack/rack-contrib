# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/garbagecollector'

describe 'Rack::GarbageCollector' do

  specify 'starts the garbage collector after each request' do
    app = lambda { |env|
      [200, {'content-type'=>'text/plain'}, ['Hello World']] }
    status, _headers, body = Rack::Lint.new(Rack::GarbageCollector.new(app)).call(Rack::MockRequest.env_for('/'))
    _(status).must_equal 200
    body.close
  end

end
