require 'rack/contrib'

describe "Rack::Contrib" do
  it "should expose release" do
    Rack::Contrib.should.respond_to :release
  end
end
