require 'test/spec'
require 'rack/builder'
require 'rack/mock'
require 'rack/contrib/subdomain_router'

context "Rack::Subdomain_Router" do
  specify "routes to proper subdomain" do

    sub1 =  lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from sub1!"]] }
    sub2 = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from sub2!"]] }
    www = lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from www!"]] }

    app = Rack::Builder.new do

      use Rack::SubdomainRouter, "test.com",
      {
        /^(www\.)?(sub1)/ => sub1,
        /^sub2/ => sub2,
        /^www/ => www
      }

      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["hi from default!"]] }
    end


    response = Rack::MockRequest.new(app).get('http://sub1.test.com/')
    response.body.should.equal('hi from sub1!')

    response = Rack::MockRequest.new(app).get('http://www.sub1.test.com/')
    response.body.should.equal('hi from sub1!')

    response = Rack::MockRequest.new(app).get('http://www.test.com/')
    response.body.should.equal('hi from www!')

    response = Rack::MockRequest.new(app).get('http://sub2.test.com/')
    response.body.should.equal('hi from sub2!')

    response = Rack::MockRequest.new(app).get('http://test.com/')
    response.body.should.equal('hi from default!')

  end

end
