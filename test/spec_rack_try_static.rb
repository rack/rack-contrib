require 'minitest/autorun'

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
  describe 'when file cannot be found' do
    it 'should call call app' do
      res = request(build_options(:try => ['html'])).get('/statics')
      res.ok?.must_equal(true)
      res.body.must_equal "Hello World"
    end
  end

  describe 'when file can be found' do
    it 'should serve first found' do
      res = request(build_options(:try => ['.html', '/index.html', '/index.htm'])).get('/statics')
      res.ok?.must_equal(true)
      res.body.strip.must_equal "index.html"
    end
  end

  describe 'when path_info maps directly to file' do
    it 'should serve existing' do
      res = request(build_options(:try => ['/index.html'])).get('/statics/existing.html')
      res.ok?.must_equal(true)
      res.body.strip.must_equal "existing.html"
    end
  end

  describe 'when sharing options' do
    it 'should not mutate given options' do
      org_options = build_options  :try => ['/index.html']
      given_options = org_options.dup
      request(given_options).get('/statics').ok?.must_equal(true)
      request(given_options).get('/statics').ok?.must_equal(true)
      given_options.must_equal org_options
    end
  end
end
