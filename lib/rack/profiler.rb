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
      if mode = profiling?(env)
        profile(env, mode)
      else
        @app.call(env)
      end
    end

    private
      def profile(env, mode)
        RubyProf.measure_mode = RubyProf.const_get(mode.upcase)
        result = RubyProf.profile { @app.call(env) }
        [200, calltree_headers(env, mode), calltree_body(env, result)]
      end

      def profiling?(env)
        unless RubyProf.running?
          request = Rack::Request.new(env)
          if mode = request.params.delete('profile')
            if MODES.include?(mode)
              mode
            else
              env['rack.errors'] << "Invalid RubyProf measure_mode: #{mode}. Use one of #{MODES.to_a.join(', ')}"
              false
            end
          end
        end
      end

      def calltree_headers(env, mode)
        { 'Content-Type' => 'application/octet-stream',
          'Content-Disposition' => %(attachment; filename="#{::File.basename(env['PATH_INFO'])}.#{mode}.tree") }
      end

      def calltree_body(env, result)
        body = StringIO.new
        RubyProf::CallTreePrinter.new(result).print(body, :min_percent => 0.01)
        body.rewind
        body
      end
  end
end
