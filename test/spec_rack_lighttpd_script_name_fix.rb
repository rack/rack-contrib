require 'test/spec'
require 'rack/mock'
require 'rack/contrib/lighttpd_script_name_fix'

context "Rack::LighttpdScriptNameFix" do
  specify "corrects SCRIPT_NAME and PATH_INFO set by lighttpd " do
    env = {
      "PATH_INFO" => "/foo/bar/baz",
      "SCRIPT_NAME" => "/hello"
    }
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, World!"] }
    response = Rack::LighttpdScriptNameFix.new(app).call(env)
    env['SCRIPT_NAME'].should.be.empty
    env['PATH_INFO'].should.equal '/hello/foo/bar/baz'
  end
end
