module Rack
  class Backstage
    File = ::File

    def initialize(app, path)
      @app = app
      @file = File.expand_path(path)
    end

    def call(env)
      if File.exists?(@file)
        content = File.read(@file)
        length = "".respond_to?(:bytesize) ? content.bytesize.to_s : content.size.to_s
        [503, {'Content-Type' => 'text/html', 'Content-Length' => length}, [content]]
      else
        @app.call(env)
      end
    end
  end
end
