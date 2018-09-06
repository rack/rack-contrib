require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/transform_keys'
require 'json'

describe 'Rack::TransformKeys' do
  def request(request_params, response_params)
    transformed_keys_app = lambda do |env|
      # check if transformed keys are equal to our expectations
      # after testing subject had been called
      request = Rack::Request.new(env)
      request.params.must_equal(response_params)
      Rack::Response.new(request.params.map(&:to_json), 200, 'Content-Type' => 'application/json')
    end

    mock_app = lambda do |env|
      if env['QUERY_STRING'].empty?
        copied_request_params = JSON.parse(request_params.to_json)

        # set params
        request = Rack::Request.new(env)
        request_params.each { |k, v| request.update_param(k, v) }
      end

      # call testing subject
      status, header, body = Rack::TransformKeys.new(transformed_keys_app).call(env)

      # set body to array of json objects
      new_body = []
      body.each do |b|
        new_body.push(JSON.parse(b))
      end

      # test for equality
      new_body.must_equal([copied_request_params || request_params])

      [status, header, new_body]
    end
    @request = Rack::MockRequest.new(mock_app)
  end

  def json_request(request_params, response_params, query_path)
    request(request_params, response_params).get(query_path, 'Content-Type' => 'application/json')
  end

  specify 'simple hash for body' do
    json_request({ 'newName' => 'henry whoever' }, { 'new_name' => 'henry whoever' }, '/')
  end

  specify 'nested hash for body' do
    json_request(
      { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } },
      { 'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' } },
      '/'
    )
  end

  specify 'simple hash as query string' do
    query_string = 'newName=henry%20whoever'
    json_request({ 'newName' => 'henry whoever' }, { 'new_name' => 'henry whoever' }, "/?#{query_string}")
  end

  specify 'nested hash as query string' do
    query_string = 'newName[firstName]=henry&newName[lastName]=whoever'
    json_request(
      { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } },
      { 'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' } },
      "/?#{query_string}"
    )
  end

  specify 'just a simple query_string' do
    json_request({ 'string' => nil }, { 'string' => nil }, '/?string')
  end
end
