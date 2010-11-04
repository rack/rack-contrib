require 'test/spec'

require 'rack'
require 'rack/contrib/error_pages'

describe "Rack::ErrorPages" do

  context 'when the HTML file cannot be found' do
    it 'should return the original status, body and headers from the app' do

      middleware   = Rack::ErrorPages.new(lambda {|env| [200, {'Content-Type' => 'text/plain'}, 'hello rack'] })

      status, headers, body = middleware.call({})

      status.should  == 200
      headers.should == {'Content-Type' => 'text/plain'}
      body.should    == "hello rack"

    end
  end

  context 'when the HTML file can be found' do

      app = lambda {|env| [404, {'Foo' => 'Bar', 'Content-Length' => '10', 'Content-Type' => 'text/plain'}, 'hello rack'] }

      middleware   = Rack::ErrorPages.new(app, 'test')

      status, headers, body = middleware.call({})

      it 'should return the status of the original app' do
          status.should == 404
      end

      it 'should return the headers of the original app' do
          headers['Foo'].should == 'Bar'
      end

      it 'should set the content-length header to the length of the HTML file' do
          headers['Content-Length'].should == File.read('test/404.html').size.to_s
      end

      it 'should set the content-type header to text/html' do
          headers['Content-Type'].should == 'text/html'
      end

      it 'should set the body to the body contents HTML file' do
          body.should == File.read('test/404.html')
      end

  end

end
