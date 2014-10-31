require 'rack/contrib'

describe "Rack::Contrib" do
  specify "should expose release" do
    Rack::Contrib.should respond_to :release
  end
end
