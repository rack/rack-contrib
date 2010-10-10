require 'test/spec'

require 'rack'
require 'rack/contrib/try_static'
require 'rack/mock'

def request(options = {})
  options.merge!({
    :urls => %w[/],
    :root => ::File.expand_path(::File.dirname(__FILE__)),
  })

  @request =
    Rack::MockRequest.new(
      Rack::TryStatic.new(
        lambda {[200, {}, ["Hello World"]]},
        options))
end

describe "Rack::TryStatic" do
  context 'when file cannot be found' do
    it 'should call call app' do
      res = request(:try => ['html']).get('/documents')
      res.should.be.ok
      res.body.should == "Hello World"
    end
  end

  context 'when file can be found' do
    it 'should serve first found' do
      res = request(:try => ['.html', '/index.html', '/index.htm']).get('/documents')
      res.should.be.ok
      res.body.strip.should == "index.html"
    end
  end

  context 'when path_info maps directly to file' do
    it 'should serve existing' do
      res = request(:try => ['/index.html']).get('/documents/existing.html')
      res.should.be.ok
      res.body.strip.should == "existing.html"
    end
  end
end
