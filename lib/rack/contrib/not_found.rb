module Rack
  # Rack::NotFound is a default endpoint. Optionally initialize with the
  # path to a custom 404 page, to override the standard response body.
  #
  # Examples:
  #
  # Serve default 404 response:
  #   run Rack::NotFound.new
  #
  # Serve a custom 404 page:
  #   run Rack::NotFound.new('path/to/your/404.html')

  class NotFound
    F = ::File

    def initialize(path = '')
      if path.empty?
        @content = "Not found\n"
      else
        file = F.expand_path(path)
        @content = F.read(file)
      end
      @length = @content.size.to_s
    end

    def call(env)
      [404, {'Content-Type' => 'text/html', 'Content-Length' => @length}, [@content]]
    end
  end
end
