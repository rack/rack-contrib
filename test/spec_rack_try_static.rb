require 'test/spec'

require 'rack'
require 'rack/contrib/try_static'
require 'rack/mock'

def build_options(opts)
  {
    :urls => %w[/],
    :root => ::File.expand_path(::File.dirname(__FILE__)),
  }.merge(opts)
end

def request(options = {})
  @request =
    Rack::MockRequest.new(
      Rack::TryStatic.new(
        lambda { |_| [200, {}, ["Hello World"]]},
        options))
end

describe "Rack::TryStatic" do
  context 'when file cannot be found' do
    it 'should call call app' do
      res = request(build_options(:try => ['html'])).get('/documents')
      res.should.be.ok
      res.body.should == "Hello World"
    end
  end

  context 'when file can be found' do
    it 'should serve first found' do
      res = request(build_options(:try => ['.html', '/index.html', '/index.htm'])).get('/documents')
      res.should.be.ok
      res.body.strip.should == "index.html"
    end
  end

  context 'when path_info maps directly to file' do
    it 'should serve existing' do
      res = request(build_options(:try => ['/index.html'])).get('/documents/existing.html')
      res.should.be.ok
      res.body.strip.should == "existing.html"
    end
  end

  context 'when sharing options' do
    it 'should not mutate given options' do
      org_options = build_options  :try => ['/index.html']
      given_options = org_options.dup
      request(given_options).get('/documents').should.be.ok
      request(given_options).get('/documents').should.be.ok
      given_options.should == org_options
    end
  end
end
