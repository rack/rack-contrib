require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/bounce_favicon'

describe Rack::BounceFavicon do
  app = Rack::Builder.new do
    use Rack::BounceFavicon
    run lambda { |env| [200, {}, []] }
  end

  specify 'does nothing when requesting paths other than the favicon' do
    response = Rack::MockRequest.new(app).get('/')
    response.status.must_equal(200)
  end

  specify 'gives a 404 when requesting the favicon' do
    response = Rack::MockRequest.new(app).get('/favicon.ico')
    response.status.must_equal(404)
  end
end
