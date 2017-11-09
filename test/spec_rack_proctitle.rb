require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/proctitle'

describe "Rack::ProcTitle" do
  progname = ::File.basename($0)
  appname = ::File.expand_path(__FILE__).split('/')[-3]

  def simple_app(body=['Hello World!'])
    lambda { |env| [200, {'Content-Type' => 'text/plain'}, body] }
  end

  specify "should set the process title when created" do
    Rack::ProcTitle.new(simple_app)
    $0.must_equal "#{progname} [#{appname}] init ..."
  end

  specify "should set the process title on each request" do
    app = Rack::ProcTitle.new(simple_app)
    req = Rack::MockRequest.new(app)
    10.times { req.get('/hello') }
    $0.must_equal "#{progname} [#{appname}/80] (10) GET /hello"
  end
end
