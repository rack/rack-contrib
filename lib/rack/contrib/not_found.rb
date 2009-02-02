module Rack
  # Rack::NotFound is a default endpoint. Initialize with the path to
  # your 404 page.

  class NotFound
    F = ::File

    def initialize(path)
      file = F.expand_path(path)
      @content = F.read(file)
      @length = @content.size.to_s
    end

    def call(env)
      [404, {'Content-Type' => 'text/html', 'Content-Length' => @length}, [@content]]
    end
  end
end
