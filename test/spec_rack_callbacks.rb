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
  def call(env)
    $hax_logger = 'lol'
  end
end

context "Rack::Callbacks" do
  specify "works for love and small stack trace" do
    callback_app = Rack::Callbacks.new do
      before Flame
      before Pacify, "with love"

      run lambda {|env| [200, {}, env['flame'] + env['peace']] }

      after Finale
    end

    app = Rack::Builder.new do
      run callback_app
    end.to_app

    response = Rack::MockRequest.new(app).get("/")
    response.body.to_s.should.equal 'F Lifo..with love'
    $hax_logger.should.equal 'lol'
  end
end