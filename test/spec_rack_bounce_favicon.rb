# frozen_string_literal: true

require 'minitest/autorun'
require 'rack'
require 'rack/contrib/bounce_favicon'

describe Rack::BounceFavicon do
  app = Rack::Lint.new(
    Rack::Builder.new do
      use Rack::BounceFavicon
      run lambda { |env| [200, {}, []] }
    end
  )

  specify 'does nothing when requesting paths other than the favicon' do
    response = Rack::MockRequest.new(app).get('/')
    _(response.status).must_equal(200)
  end

  specify 'gives a 404 when requesting the favicon' do
    response = Rack::MockRequest.new(app).get('/favicon.ico')
    _(response.status).must_equal(404)
  end
end
