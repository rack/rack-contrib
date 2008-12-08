require 'ruby-prof'

class Profiler
  class ErrorWrapper
    def initialize(error)
      @error = error
    end

    def <<(str)
      @error.write str
      @error.flush
    end
  end

  def initialize(app, measure_mode = RubyProf::PROCESS_TIME, logger = nil)
    RubyProf.measure_mode = measure_mode
    @app = app
    @logger = logger
  end

  def call(env)
    RubyProf.start
    status, headers, body = @app.call(env)
    result = RubyProf.stop
    print_result(env, result)
    [status, headers, body]
  end

  private
    def print_result(env, result)
      logger ||= ErrorWrapper.new(env["rack.errors"])
      printer = RubyProf::FlatPrinter.new(result)
      printer.print(logger, 0)
    end
end
