require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/config'

describe "Rack::Config" do

  specify "should accept a block that modifies the environment" do
    app = Rack::Builder.new do
      use Rack::Lint
      use Rack::ContentLength
      use Rack::Config do |env|
        env['greeting'] = 'hello'
      end
      run lambda { |env|
        [200, {'Content-Type' => 'text/plain'}, [env['greeting'] || '']]
      }
    end
    response = Rack::MockRequest.new(app).get('/')
    response.body.must_equal('hello')
  end

end
