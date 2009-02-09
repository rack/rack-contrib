require 'test/spec'
require 'rack/mock'
require 'rack/contrib/profiler'

context 'Rack::Profiler' do
  
  app = lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'Oh hai der'] }
  request = Rack::MockRequest.env_for("/", :input => "profile=process_time")
  
  specify 'printer defaults to RubyProf::CallTreePrinter' do
    profiler = Rack::Profiler.new(nil)
    profiler.instance_variable_get('@printer').should.equal RubyProf::CallTreePrinter
    profiler.instance_variable_get('@times').should.equal 1
  end
  
  specify 'CallTreePrinter has correct headers' do  
    headers = Rack::Profiler.new(app).call(request)[1]
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
