gem 'ruby-prof', '>= 0.7.1'
require 'ruby-prof'
require 'set'

module Rack
  # Set the profile=process_time query parameter to download a
  # calltree profile of the request.
  class Profiler
    MODES = %w(
      process_time
      wall_time
      cpu_time
      allocations
      memory
      gc_runs
      gc_time
    ).to_set

    PRINTER_CONTENT_TYPE = {
      RubyProf::FlatPrinter => 'text/plain',
      RubyProf::GraphPrinter => 'text/plain',
      RubyProf::GraphHtmlPrinter => 'text/html',
      RubyProf::CallTreePrinter => 'application/octet-stream'
    }

    def initialize(app, printer = RubyProf::GraphHtmlPrinter)
      @app = app
      @printer = printer
    end

    def call(env)
      if mode = profiling?(env)
        profile(env, mode)
      else
        @app.call(env)
      end
    end

    private
      def profiling?(env)
        unless RubyProf.running?
          request = Rack::Request.new(env)
          if mode = request.params.delete('profile')
            if MODES.include?(mode)
              mode
            else
              env['rack.errors'].write "Invalid RubyProf measure_mode: " +
                "#{mode}. Use one of #{MODES.to_a.join(', ')}"
              false
            end
          end
        end
      end

      def profile(env, mode)
        RubyProf.measure_mode = RubyProf.const_get(mode.upcase)
        result = RubyProf.profile { @app.call(env) }
        headers = headers(@printer, env, mode)
        body = print(@printer, result)
        [200, headers, body]
      end

      def print(printer, result)
        body = StringIO.new
        printer.new(result).print(body, :min_percent => 0.01)
        body.rewind
        body
      end

      def headers(printer, env, mode)
        headers = { 'Content-Type' => PRINTER_CONTENT_TYPE[printer] }
        if printer == RubyProf::CallTreePrinter
          filename = ::File.basename(env['PATH_INFO'])
          headers['Content-Disposition'] = "attachment; " +
            "filename=\"#{filename}.#{mode}.tree\")"
        end
        headers
      end
  end
end
