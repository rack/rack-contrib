# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/mock'
require 'rack/contrib/lighttpd_script_name_fix'

describe "Rack::LighttpdScriptNameFix" do
  specify "corrects SCRIPT_NAME and PATH_INFO set by lighttpd " do
    env = Rack::MockRequest.env_for(
      '',
      {
        "PATH_INFO" => "/foo/bar/baz",
        "SCRIPT_NAME" => "/hello"
      }
    )
    app = lambda { |_| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
    response = Rack::Lint.new(Rack::LighttpdScriptNameFix.new(app)).call(env)
    _(env['SCRIPT_NAME'].empty?).must_equal(true)
    _(env['PATH_INFO']).must_equal '/hello/foo/bar/baz'
  end
end
