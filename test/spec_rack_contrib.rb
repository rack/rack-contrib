require 'test/spec'
require 'rack/contrib'

context "Rack::Contrib" do
  specify "should expose release" do
    Rack::Contrib.should.respond_to :release
  end
end
