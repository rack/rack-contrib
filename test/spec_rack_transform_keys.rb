require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/transform_keys'
require 'json'

describe 'Rack::TransformKeys' do
  def request(incoming_params, outcoming_params)
    transformed_keys_app = lambda do |env|
      # check if transformed keys are equal to our expectations
      # after testing subject had been called
      request = Rack::Request.new(env)
      request.params.must_equal(outcoming_params)
      Rack::Response.new(request.params.map(&:to_json), 200)
    end

    mock_app = lambda do |env|
      if env['QUERY_STRING'].empty?
        copied_incoming_params = JSON.parse(incoming_params.to_json)

        # set params
        request = Rack::Request.new(env)
        incoming_params.each { |k, v| request.update_param(k, v) }
      end

      # call testing subject
      status, header, body = Rack::TransformKeys.new(transformed_keys_app).call(env)

      # set body to proper object
      new_body = []
      body.each do |b|
        new_body.push(JSON.parse(b))
      end

      # test for equality
      new_body.must_equal([copied_incoming_params || incoming_params])

      [status, header, new_body]
    end
    @request = Rack::MockRequest.new(mock_app)
  end

  specify 'simple hash for body' do
    request({ 'newName' => 'henry whoever' }, 'new_name' => 'henry whoever').get('/')
  end

  specify 'nested hash for body' do
    request(
      { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } },
      'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' }
    ).get('/')
  end

  specify 'simple hash as query string' do
    query_string = 'newName=henry%20whoever'
    request({ 'newName' => 'henry whoever' }, 'new_name' => 'henry whoever').get("/?#{query_string}")
  end

  specify 'nested hash as query string' do
    query_string = 'newName[firstName]=henry&newName[lastName]=whoever'
    request(
      { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } },
      'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' }
    ).get("/?#{query_string}")
  end

  specify 'just a simple query_string' do
    request({ 'string' => nil }, 'string' => nil).get('/?string')
  end
end
