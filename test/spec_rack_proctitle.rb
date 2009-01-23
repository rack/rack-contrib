require 'test/spec'
require 'rack/mock'
require 'rack/contrib/proctitle'

context "Rack::ProcTitle" do
  F = ::File

  progname = File.basename($0)
  appname = F.expand_path(__FILE__).split('/')[-3]

  def simple_app(body=['Hello World!'])
    lambda { |env| [200, {'Content-Type' => 'text/plain'}, body] }
  end

  specify "should set the process title when created" do
    Rack::ProcTitle.new(simple_app)
    $0.should.equal "#{progname} [#{appname}] init ..."
  end

  specify "should set the process title on each request" do
    app = Rack::ProcTitle.new(simple_app)
    req = Rack::MockRequest.new(app)
    10.times { req.get('/hello') }
    $0.should.equal "#{progname} [#{appname}/80] (10) GET /hello"
  end
end
