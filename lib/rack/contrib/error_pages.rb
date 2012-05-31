module Rack

  #
  # Serve static error pages based on status code if they exist.
  #
  # If your app returns a status code with a matching :status.html file
  # in the static_dir then this file will be served
  #
  # EG: Your app returns a 500 status, this middleware serves the file
  # found at "#{static_dir}/500.html"
  #
  # Implements some memoization so files are read only once per process
  # and only when required
  #
  # Matt Haynes 2010
  #

  class ErrorPages

    F = ::File

    def initialize(app, static_dir = 'public')

        @app    = app

        @pages  = Hash.new do |hash, key|

            path = F.expand_path("#{static_dir}/#{key}.html")

            if F.exists? path
                content = F.read(path)
                length  = content.size.to_s
                hash[key] = [content, length]
            else
                hash[key] = nil
            end

        end

    end

    def call(env)

        status, headers, body = @app.call(env)

        if @pages[status].nil?
            [status, headers, body]
        else
            [status, headers.merge({ 'Content-Type' => 'text/html', 'Content-Length' => @pages[status][1] }), @pages[status][0]]
        end

    end

  end

end

