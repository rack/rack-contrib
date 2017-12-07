require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/not_found'
require 'tempfile'

describe "Rack::NotFound" do

  specify "should render the file at the given path for all requests" do
    app = Rack::Builder.new do
      use Rack::Lint
      run Rack::NotFound.new('test/404.html')
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal('Custom 404 page content')
    response.headers['Content-Length'].must_equal('23')
    response.headers['Content-Type'].must_equal('text/html')
    response.status.must_equal(404)
  end

  specify "should render the default response body if no path specified" do
    app = Rack::Builder.new do
      use Rack::Lint
      run Rack::NotFound.new
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal("Not found\n")
    response.headers['Content-Length'].must_equal('10')
    response.headers['Content-Type'].must_equal('text/html')
    response.status.must_equal(404)
  end

  specify "should accept an alternate content type" do
    app = Rack::Builder.new do
      use Rack::Lint
      run Rack::NotFound.new(nil, 'text/plain')
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal("Not found\n")
    response.headers['Content-Length'].must_equal('10')
    response.headers['Content-Type'].must_equal('text/plain')
    response.status.must_equal(404)
  end

  specify "should return correct size" do
    Tempfile.open('test') do |f|
      f.write '<!DOCTYPE html>'
      f.write '<meta charset=utf-8>'
      f.write '☃ snowman'
      f.close
      app = Rack::Builder.new do
        use Rack::Lint
        run Rack::NotFound.new(f.path)
      end
      response = Rack::MockRequest.new(app).get('/')
      response.headers['Content-Length'].must_equal('46')
    end
  end
end
