require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/transform_keys'
require 'json'

describe 'Rack::TransformKeys' do
  def request(request_params, application_params, query_path, response_params = JSON.parse(request_params.to_json))
    mock_application_app = lambda do |env|
      request = Rack::Request.new(env)
      request.params.must_equal(application_params)
      Rack::Response.new([request.params].map(&:to_json), 200, 'Content-Type' => 'application/json')
    end

    mock_request_app = lambda do |env|
      status, header, body = Rack::TransformKeys.new(mock_application_app).call(env)
      JSON.parse(body.body[0]).must_equal(response_params)
      Rack::Response.new(body, 200)
    end

    mock_request = Rack::MockRequest.new(mock_request_app)
    request_options = {
      'Content-Type' => 'application/json',
      params: request_params
    }
    mock_request.get(query_path, request_options)
    mock_request.post(query_path, request_options)
  end

  specify 'test simple hash' do
    request({ 'newName' => 'henry whoever' }, { 'new_name' => 'henry whoever' }, '/')
    request({ 'newName' => nil }, { 'new_name' => nil }, '/')
    request({ 'newname' => nil }, { 'newname' => nil }, '/')
    request({ 'nEwNaMe' => nil }, { 'n_ew_na_me' => nil }, '/')
    # the following cases demonstrate it's not a symmetric relation
    request({ '___' => nil }, { '___' => nil }, '/', '' => nil)
    request({ 'nEWNAME' => nil }, { 'n_ewname' => nil }, '/', 'nEwname' => nil)
    request({ 'NeWnAmE' => nil }, { 'ne_wn_am_e' => nil }, '/', 'neWnAmE' => nil)
  end

  specify 'test nested hash' do
    request(
      { 'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' } },
      { 'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' } },
      '/'
    )
  end

  specify 'simple hash as query string' do
    query_string = 'newName=henry%20whoever'
    request(nil, { 'new_name' => 'henry whoever' }, "/?#{query_string}", 'newName' => 'henry whoever')
  end

  specify 'nested hash as query string' do
    query_string = 'newName[firstName]=henry&newName[lastName]=whoever'
    request(
      nil,
      { 'new_name' => { 'first_name' => 'henry', 'last_name' => 'whoever' } },
      "/?#{query_string}",
      'newName' => { 'firstName' => 'henry', 'lastName' => 'whoever' }
    )
  end

  specify 'just a simple query_string' do
    request(nil, { 'new_name' => nil }, '/?newName', 'newName' => nil)
  end
end
