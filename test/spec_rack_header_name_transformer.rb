# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/contrib/runtime'

describe Rack::HeaderNameTransformer do
  response = ->(_e) { [200, {}, []] }

  it 'leaves the value of headers intact if there is no matching vendor header passed to override it in the request' do
    vendor_header = 'not passed in the request'
    env = Rack::MockRequest.env_for('/', 'HTTP_X_FORWARDED_PROTO' => 'http')

    Rack::Lint.new(Rack::HeaderNameTransformer.new(response, vendor_header, 'bar')).call env

    env['HTTP_X_FORWARDED_PROTO'].must_equal 'http'
  end

  it 'copy the value of the vendor header to a newly named header' do
    env = Rack::MockRequest.env_for('/', { 'HTTP_VENDOR' => 'value', 'HTTP_FOO' => 'foo' })

    Rack::Lint.new(Rack::HeaderNameTransformer.new(response, 'Vendor', 'Standard')).call env
    Rack::Lint.new(Rack::HeaderNameTransformer.new(response, 'Foo', 'Bar')).call env

    env['HTTP_STANDARD'].must_equal 'value'
    env['HTTP_BAR'].must_equal 'foo'

    # This is a copy operation, so the original headers are still preserved
    env['HTTP_VENDOR'].must_equal 'value'
    env['HTTP_FOO'].must_equal 'foo'
  end

  # Real world headers and use cases
  it 'copy the value of a vendor forward proto header to the standardised forward proto header' do
    env = Rack::MockRequest.env_for('/', 'HTTP_VENDOR_FORWARDED_PROTO_HEADER' => 'https')

    Rack::Lint.new(
      Rack::HeaderNameTransformer.new(
        response,
        'Vendor-Forwarded-Proto-Header',
        'X-Forwarded-Proto'
      )
    ).call env

    env['HTTP_X_FORWARDED_PROTO'].must_equal 'https'
  end

  it 'copy the value of a vendor forward proto header to the standardised header, overwriting existing request value' do
    env = Rack::MockRequest.env_for(
      '/',
      'HTTP_VENDOR_FORWARDED_PROTO_HEADER' => 'https',
      'HTTP_X_FORWARDED_PROTO' => 'http'
    )

    Rack::Lint.new(
      Rack::HeaderNameTransformer.new(
        response,
        'Vendor-Forwarded-Proto-Header',
        'X-Forwarded-Proto'
      )
    ).call env

    env['HTTP_X_FORWARDED_PROTO'].must_equal 'https'
  end
end
