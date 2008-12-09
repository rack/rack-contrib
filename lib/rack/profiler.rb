require 'ruby-prof'
require 'set'

module Rack
  # Set the profile=process_time query parameter to download a calltree profile of the request.
  class Profiler
    MODES = %w(process_time wall_time cpu_time allocations memory gc_runs gc_time).to_set

    def initialize(app)
      @app = app
    end

    def call(env)
      if profiling?(env)
        profile(env)
      else
        @app.call(env)
      end
    end

    private
      def profile(env)
        RubyProf.measure_mode = RubyProf.const_get(env['rack.profiler.measure_mode'].upcase)
        result = RubyProf.profile { @app.call(env) }
        [200, calltree_headers(env), calltree_body(env, result)]
      end

      def profiling?(env)
        if RubyProf.running?
          false
        else
          request = Rack::Request.new(env)
          if mode = request.params.delete('profile')
            if MODES.include?(mode)
              env['rack.profiler.measure_mode'] = mode
              env['rack.profiler.min_precent'] = (request.params.delete('min_percent') || 0.01).to_f
              true
            else
              env['rack.errors'] << "Invalid RubyProf measure_mode: #{mode}. Use one of #{MODES.to_a.join(', ')}"
              false
            end
          else
            false
          end
        end
      end

      def calltree_headers(env)
        { 'Content-Type' => 'application/octet-stream',
          'Content-Disposition' => %(attachment; filename="#{::File.basename(env['PATH_INFO'])}.#{env['rack.profiler.measure_mode']}.tree") }
      end

      def calltree_body(env, result)
        body = StringIO.new
        RubyProf::CallTreePrinter.new(result).print(body, :min_percent => env['rack.profiler.min_percent'])
        body.rewind
        body
      end
  end
end
