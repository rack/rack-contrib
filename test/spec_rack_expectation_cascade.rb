require 'test/spec'
require 'rack/mock'
require 'rack/contrib/expectation_cascade'

context "Rack::ExpectationCascade" do
  specify "with no apps returns a 404 if no expectation header was set" do
    app = Rack::ExpectationCascade.new
    env = {}
    response = app.call(env)
    response[0].should.equal 404
    env.should.equal({})
  end

  specify "with no apps returns a 417 if expectation header was set" do
    app = Rack::ExpectationCascade.new
    env = {"Expect" => "100-continue"}
    response = app.call(env)
    response[0].should.equal 417
    env.should.equal({"Expect" => "100-continue"})
  end

  specify "returns first successful response" do
    app = Rack::ExpectationCascade.new do |cascade|
      cascade << lambda { |env| [417, {"Content-Type" => "text/plain"}, []] }
      cascade << lambda { |env| [200, {"Content-Type" => "text/plain"}, ["OK"]] }
    end
    response = app.call({})
    response[0].should.equal 200
    response[2][0].should.equal "OK"
  end

  specify "expectation is set if it has not been already" do
    app = Rack::ExpectationCascade.new do |cascade|
      cascade << lambda { |env| [200, {"Content-Type" => "text/plain"}, ["Expect: #{env["Expect"]}"]] }
    end
    response = app.call({})
    response[0].should.equal 200
    response[2][0].should.equal "Expect: 100-continue"
  end

  specify "returns a 404 if no apps where matched and no expectation header was set" do
    app = Rack::ExpectationCascade.new do |cascade|
      cascade << lambda { |env| [417, {"Content-Type" => "text/plain"}, []] }
    end
    response = app.call({})
    response[0].should.equal 404
    response[2][0].should.equal nil
  end

  specify "returns a 417 if no apps where matched and a expectation header was set" do
    app = Rack::ExpectationCascade.new do |cascade|
      cascade << lambda { |env| [417, {"Content-Type" => "text/plain"}, []] }
    end
    response = app.call({"Expect" => "100-continue"})
    response[0].should.equal 417
    response[2][0].should.equal nil
  end

  specify "nests expectation cascades" do
    app = Rack::ExpectationCascade.new do |c1|
      c1 << Rack::ExpectationCascade.new do |c2|
        c2 << lambda { |env| [417, {"Content-Type" => "text/plain"}, []] }
      end
      c1 << Rack::ExpectationCascade.new do |c2|
        c2 << lambda { |env| [200, {"Content-Type" => "text/plain"}, ["OK"]] }
      end
    end
    response = app.call({})
    response[0].should.equal 200
    response[2][0].should.equal "OK"
  end
end
