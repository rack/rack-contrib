require 'test/spec'
require 'rack/mock'

begin
  require 'rack/contrib/profiler'

  context 'Rack::Profiler' do
    app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'Oh hai der'] }
    request = Rack::MockRequest.env_for("/", :params => "profile=process_time")

    specify 'printer defaults to RubyProf::CallStackPrinter' do
      profiler = Rack::Profiler.new(nil)
      profiler.instance_variable_get('@printer').should.equal RubyProf::CallStackPrinter
      profiler.instance_variable_get('@times').should.equal 1
    end

    specify 'call @times globally and times is set' do
        profiler = Rack::Profiler.new(app, :times => 4) 
        profiler.instance_variable_get('@times').should.equal 4
    end

    specify 'CallStackPrinter has Content-Type test/html' do
      headers = Rack::Profiler.new(app, :printer => :call_stack).call(request)[1]
      headers.should.equal "Content-Type"=>"text/html"
    end

    specify 'CallTreePrinter has correct headers' do
      headers = Rack::Profiler.new(app, :printer => :call_tree).call(request)[1]
      headers.should.equal "Content-Disposition"=>"attachment; filename=\"/.process_time.tree\"", "Content-Type"=>"application/octet-stream"
    end

    specify 'FlatPrinter and GraphPrinter has Content-Type text/plain' do
      %w(flat graph).each do |printer|
        headers = Rack::Profiler.new(app, :printer => printer.to_sym).call(request)[1]
        headers.should.equal "Content-Type"=>"text/plain"
      end
    end

    specify 'GraphHtmlPrinter has Content-Type text/html' do
      headers = Rack::Profiler.new(app, :printer => :graph_html).call(request)[1]
      headers.should.equal "Content-Type"=>"text/html"
    end
  end

rescue LoadError => boom
  $stderr.puts "WARN: Skipping Rack::Profiler tests (ruby-prof not installed)"
end
