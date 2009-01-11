module Rack
  # Forces garbage collection after each request.
  class GarbageCollector
    def initialize(app)
      @app = app
    end

    def call(env)
      res = @app.call(env)
      GC.start
      res
    end
  end
end
