# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/garbagecollector'

describe Rack::GarbageCollector do

  def app
    -> (env) { [200, {}, ['Hello World']] }
  end

  def mock_env
    headers = { 'REQUEST_METHOD' => 'POST' }
    Rack::MockRequest.env_for '/', headers
  end

  specify 'starts the garbage collector after each request' do
    Rack::Lint.new(Rack::GarbageCollector.new(app)).call(mock_env)
  end

end
