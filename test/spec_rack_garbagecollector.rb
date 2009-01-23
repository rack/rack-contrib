require 'test/spec'
require 'rack/mock'
require 'rack/contrib/garbagecollector'

context 'Rack::GarbageCollector' do

  specify 'starts the garbage collector after each request' do
    app = lambda { |env|
      [200, {'Content-Type'=>'text/plain'}, ['Hello World']] }
    Rack::GarbageCollector.new(app).call({})
  end

end
