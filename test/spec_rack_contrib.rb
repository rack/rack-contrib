require 'minitest/autorun'
require 'rack/contrib'

describe "Rack::Contrib" do
  specify "should expose release" do
    Rack::Contrib.must_respond_to(:release)
  end
end
