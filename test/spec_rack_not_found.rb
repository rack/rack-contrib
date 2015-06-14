require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/not_found'

describe "Rack::NotFound" do

  specify "should render the file at the given path for all requests" do
    app = Rack::Builder.new do
      use Rack::Lint
      run Rack::NotFound.new('test/404.html')
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal('Not Found')
    response.status.must_equal(404)
  end

end
