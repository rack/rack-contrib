require 'test/spec'
require 'rack/mock'

class Flame
  def call(env)
    env['flame'] = 'F Lifo..'
  end
end

class Pacify
  def initialize(with)
    @with = with
  end

  def call(env)
    env['peace'] = @with
  end
end

class Finale
  def call(response)
    status, headers, body = response

    headers['last'] = 'Finale'
    $old_status = status

    [201, headers, body]
  end
end

class TheEnd
  def call(response)
    status, headers, body = response

    headers['last'] = 'TheEnd'
    [201, headers, body]
  end
end

context "Rack::Callbacks" do
  specify "works for love and small stack trace" do
    callback_app = Rack::Callbacks.new do
      before Flame
      before Pacify, "with love"

      run lambda {|env| [200, {}, env['flame'] + env['peace']] }

      after Finale
      after TheEnd
    end

    app = Rack::Builder.new do
      run callback_app
    end.to_app

    response = Rack::MockRequest.new(app).get("/")

    response.body.should.equal 'F Lifo..with love'

    $old_status.should.equal 200
    response.status.should.equal 201

    response.headers['last'].should.equal 'TheEnd'
  end
end