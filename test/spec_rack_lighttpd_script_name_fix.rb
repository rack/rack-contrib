require 'rack/mock'
require 'rack/contrib/lighttpd_script_name_fix'

describe "Rack::LighttpdScriptNameFix" do
  it "corrects SCRIPT_NAME and PATH_INFO set by lighttpd " do
    env = {
      "PATH_INFO" => "/foo/bar/baz",
      "SCRIPT_NAME" => "/hello"
    }
    app = lambda { |_| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
    response = Rack::LighttpdScriptNameFix.new(app).call(env)
    env['SCRIPT_NAME'].should.be.empty
    env['PATH_INFO'].should.equal '/hello/foo/bar/baz'
  end
end
