require 'ruby-prof'

module Rack
  # Set the profile=process_time query parameter to download a
  # calltree profile of the request.
  #
  # Pass the :printer option to pick a different result format.
  class Profiler
    MODES = %w(process_time wall_time cpu_time
               allocations memory gc_runs gc_time)

    DEFAULT_PRINTER = :call_stack

    CONTENT_TYPES = Hash.new('application/octet-stream').merge(
      'RubyProf::FlatPrinter'      => 'text/plain',
      'RubyProf::GraphPrinter'     => 'text/plain',
      'RubyProf::GraphHtmlPrinter' => 'text/html',
      'RubyProf::CallStackPrinter' => 'text/html')

    # Accepts a :printer => [:call_stack|:call_tree|:graph_html|:graph|:flat]
    # option defaulting to :call_stack.
    def initialize(app, options = {})
      @app = app
      @printer = parse_printer(options[:printer] || DEFAULT_PRINTER)
      @times = (options[:times] || 1).to_i
    end

    def call(env)
      if mode = profiling?(env)
        @times = @request.params['times'].to_i if @request.params['times']
        profile(env, mode)
      else
        @app.call(env)
      end
    end

    private
      def profiling?(env)
        unless ::RubyProf.running?
          @request = Rack::Request.new(env.clone)
          if mode = @request.params.delete('profile')
            if ::RubyProf.const_defined?(mode.upcase)
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
        ::RubyProf.measure_mode = ::RubyProf.const_get(mode.upcase)

        GC.enable_stats if GC.respond_to?(:enable_stats)
        result = ::RubyProf.profile do
          @times.times { @app.call(env) }
        end
        GC.disable_stats if GC.respond_to?(:disable_stats)

        [200, headers(@printer, env, mode), print(@printer, result)]
      end

      def print(printer, result)
        body = StringIO.new
        printer.new(result).print(body, :min_percent => 0.01)
        body.rewind
        body
      end

      def headers(printer, env, mode)
        headers = { 'Content-Type' => CONTENT_TYPES[printer.name] }
        if printer == ::RubyProf::CallTreePrinter
          filename = ::File.basename(env['PATH_INFO'])
          headers['Content-Disposition'] =
            %(attachment; filename="#{filename}.#{mode}.tree")
        end
        headers
      end

      def parse_printer(printer)
        if printer.is_a?(Class)
          printer
        else
          name = "#{camel_case(printer)}Printer"
          if ::RubyProf.const_defined?(name)
            ::RubyProf.const_get(name)
          else
            ::RubyProf::FlatPrinter
          end
        end
      end

      def camel_case(word)
        word.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
      end
  end
end
